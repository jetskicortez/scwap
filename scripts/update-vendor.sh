#!/usr/bin/env bash
# =============================================================================
# update-vendor.sh — Re-vendor the upstream projects into scwap
# =============================================================================
#
# Clones each upstream at the ref you pin, copies the vendored file sets into
# plugins/scwap/ (the installable payload), mirrors that payload to the repo
# root copy, prints the SHAs, and reminds you of the manual steps.
#
# USAGE:
#   SUPERPOWERS_REF=v7.0.1 PONYTAIL_REF=v5.3.2 CAVEMAN_REF=v4.0.1 \
#     bash scripts/update-vendor.sh
#
# Refs are tags or branch names (not bare SHAs); they default to each upstream's default-branch HEAD. Impeccable is NOT
# handled here: since 4.4.0 its skill ships a launcher that downloads a native
# engine binary; re-vendoring it is a deliberate, reviewed step.
#
# Work happens in $REPO/.vendor-tmp/ (gitignored, removed on success).
# Does not push, bump versions, edit THIRD_PARTY_NOTICES.md, or run tests.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
P="$REPO/plugins/scwap"
VENDOR_TMP="$REPO/.vendor-tmp"

echo "==> update-vendor.sh  repo=$REPO"
grep -qF '.vendor-tmp/' "$REPO/.gitignore" 2>/dev/null || printf '\n.vendor-tmp/\n' >> "$REPO/.gitignore"
rm -rf "$VENDOR_TMP"; mkdir -p "$VENDOR_TMP"

clone_upstream() { # dir url ref
  echo "--> Cloning $2 ${3:+@ $3}"
  if [[ -n "${3:-}" ]]; then git clone -q --depth=1 --branch "$3" "$2" "$VENDOR_TMP/$1"
  else git clone -q --depth=1 "$2" "$VENDOR_TMP/$1"; fi
}
copy_skill() { # src_skills_dir name
  rm -rf "$P/skills/$2"; cp -r "$1/$2" "$P/skills/$2"; echo "    skill: $2"
}

# --- ponytail ---------------------------------------------------------------
clone_upstream ponytail https://github.com/DietrichGebert/ponytail "${PONYTAIL_REF:-}"
PT="$VENDOR_TMP/ponytail"
for f in ponytail-activate.js ponytail-mode-tracker.js ponytail-subagent.js ponytail-config.js \
         ponytail-runtime.js ponytail-instructions.js ponytail-map.js ponytail-band-import.js \
         ponytail-statusline.sh ponytail-statusline.ps1; do
  cp "$PT/hooks/$f" "$P/hooks/$f"; echo "    hook: $f"
done
for s in ponytail ponytail-audit ponytail-debt ponytail-gain ponytail-help ponytail-review; do copy_skill "$PT/skills" "$s"; done
cp "$PT"/commands/ponytail*.toml "$P/commands/"
cp "$PT/LICENSE" "$P/licenses/LICENSE-ponytail"
PONYTAIL_SHA="$(git -C "$PT" rev-parse HEAD)"
# (hooks/band/ + hooks/claude-band.json — the optional task band — are not bundled)

# --- caveman ----------------------------------------------------------------
clone_upstream caveman https://github.com/JuliusBrussee/caveman "${CAVEMAN_REF:-}"
CM="$VENDOR_TMP/caveman"
for f in caveman-activate.js caveman-config.js caveman-mode-tracker.js caveman-parse.js caveman-stats.js \
         caveman-host-session-start.js cavecrew-model-overrides.js caveman-statusline.sh caveman-statusline.ps1; do
  cp "$CM/src/hooks/$f" "$P/hooks/$f"; echo "    hook: $f"
done
for s in caveman ultracave megacave caveman-commit caveman-help caveman-review caveman-compress; do copy_skill "$CM/skills" "$s"; done
for c in caveman ultracave megacave caveman-commit caveman-review; do cp "$CM/commands/$c.toml" "$P/commands/"; done
cp "$CM/LICENSE" "$P/licenses/LICENSE-caveman"
cp "$CM/NOTICE" "$P/licenses/NOTICE-caveman"
CAVEMAN_SHA="$(git -C "$CM" rev-parse HEAD)"

# --- superpowers ------------------------------------------------------------
clone_upstream superpowers https://github.com/obra/superpowers "${SUPERPOWERS_REF:-}"
SP="$VENDOR_TMP/superpowers"
for d in "$SP"/skills/*/; do copy_skill "$SP/skills" "$(basename "$d")"; done
for f in session-start run-hook.cmd hooks-cursor.json; do cp "$SP/hooks/$f" "$P/hooks/$f"; echo "    hook: $f"; done
cp "$SP/LICENSE" "$P/licenses/LICENSE-superpowers"
SUPERPOWERS_SHA="$(git -C "$SP" rev-parse HEAD)"
# (hooks.json is replaced by hooks/scwap-hooks.json; session-start-codex is scwap-owned)

# --- mirror payload to the repo root copy -----------------------------------
for d in hooks skills commands agents licenses rules; do rm -rf "$REPO/$d"; cp -r "$P/$d" "$REPO/$d"; done
cp "$P/THIRD_PARTY_NOTICES.md" "$REPO/THIRD_PARTY_NOTICES.md"

rm -rf "$VENDOR_TMP"

cat <<SUMMARY
============================================================
  Vendor update complete
    ponytail    $PONYTAIL_SHA
    caveman     $CAVEMAN_SHA
    superpowers $SUPERPOWERS_SHA
  Manual steps:
    1. Update pins/versions in plugins/scwap/THIRD_PARTY_NOTICES.md, then
       cp it to the repo root.
    2. Bump "version" in all four plugin.json files.
    3. node --test tests/structure.test.mjs
    4. Smoke each hook in hooks/scwap-hooks.json and scwap-codex-hooks.json
       with an isolated CLAUDE_CONFIG_DIR / PLUGIN_DATA, then commit and PR.
============================================================
SUMMARY
