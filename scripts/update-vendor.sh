#!/usr/bin/env bash
# =============================================================================
# update-vendor.sh — Re-vendor the three upstream projects into scwap
# =============================================================================
#
# PURPOSE:
#   Clones each upstream to a temp dir, copies the correct file sets into
#   the repo's flat hooks/, skills/, commands/, and licenses/ directories,
#   prints the new SHAs, and reminds the maintainer to bump version metadata.
#
# USAGE:
#   bash scripts/update-vendor.sh
#
# OPTIONAL ENV VARS (pin a specific ref; defaults to default-branch HEAD):
#   PONYTAIL_REF       e.g. "main" or "abc1234"
#   CAVEMAN_REF        e.g. "main" or "abc1234"
#   SUPERPOWERS_REF    e.g. "main" or "abc1234"
#
# TEMP DIR:
#   Work happens inside $REPO/.vendor-tmp/ — this directory should be listed
#   in .gitignore (the script enforces this; see below). It is deleted at the
#   end of a successful run.
#
# WHAT IT DOES NOT DO:
#   - Push anything to remote
#   - Modify plugin.json or THIRD_PARTY_NOTICES.md (those are your manual step)
#   - Run tests (also listed in the reminder block at the end)
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# 0. Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

VENDOR_TMP="$REPO/.vendor-tmp"

echo "==> update-vendor.sh"
echo "    repo : $REPO"
echo "    tmp  : $VENDOR_TMP"
echo ""

# ---------------------------------------------------------------------------
# 0a. Guard: ensure .vendor-tmp/ is in .gitignore
# ---------------------------------------------------------------------------

GITIGNORE="$REPO/.gitignore"

if ! grep -qF '.vendor-tmp/' "$GITIGNORE" 2>/dev/null; then
  echo "--> Adding .vendor-tmp/ to .gitignore"
  printf '\n.vendor-tmp/\n' >> "$GITIGNORE"
else
  echo "--> .vendor-tmp/ already in .gitignore"
fi
echo ""

# ---------------------------------------------------------------------------
# 0b. Create (or re-use) the temp directory
# ---------------------------------------------------------------------------

mkdir -p "$VENDOR_TMP"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

# clone_upstream UPSTREAM_DIR URL [REF]
#   Clones URL into VENDOR_TMP/UPSTREAM_DIR; checks out REF if provided.
clone_upstream() {
  local dir="$1"
  local url="$2"
  local ref="${3:-}"
  local dest="$VENDOR_TMP/$dir"

  echo "--> Cloning $url"
  git clone --depth=1 "$url" "$dest"

  if [[ -n "$ref" ]]; then
    echo "    Checking out ref: $ref"
    # fetch enough history to reach the ref if --depth=1 didn't include it
    git -C "$dest" fetch --depth=1 origin "$ref" 2>/dev/null || \
      git -C "$dest" fetch origin "$ref"
    git -C "$dest" checkout "$ref"
  fi
}

# copy_hook SRC_DIR FILENAME
#   Copies a single file from SRC_DIR into $REPO/hooks/.
copy_hook() {
  local src_dir="$1"
  local filename="$2"
  echo "    hook: $filename"
  cp "$src_dir/$filename" "$REPO/hooks/$filename"
}

# copy_skill SRC_SKILLS_DIR SKILL_NAME
#   Recursively copies skills/<SKILL_NAME>/ from the upstream to $REPO/skills/.
copy_skill() {
  local src_skills_dir="$1"
  local skill_name="$2"
  echo "    skill: $skill_name"
  rm -rf "$REPO/skills/$skill_name"
  cp -r "$src_skills_dir/$skill_name" "$REPO/skills/$skill_name"
}

# copy_commands_glob SRC_DIR GLOB
#   Copies files matching GLOB from SRC_DIR into $REPO/commands/.
#   Tolerates absence (best-effort).
copy_commands_glob() {
  local src_dir="$1"
  local glob="$2"
  local found=0
  for f in "$src_dir"/$glob; do
    [[ -e "$f" ]] || continue
    echo "    command: $(basename "$f")"
    cp "$f" "$REPO/commands/$(basename "$f")"
    found=1
  done
  if [[ $found -eq 0 ]]; then
    echo "    (no files matching $glob — skipping)"
  fi
}

# ---------------------------------------------------------------------------
# 1. ponytail — https://github.com/DietrichGebert/ponytail
# ---------------------------------------------------------------------------

echo "============================================================"
echo "  [1/3] ponytail"
echo "============================================================"

PONYTAIL_REF="${PONYTAIL_REF:-}"
clone_upstream "ponytail" "https://github.com/DietrichGebert/ponytail" "$PONYTAIL_REF"

PT_DIR="$VENDOR_TMP/ponytail"

# hooks: from upstream hooks/
echo "  Copying hooks..."
for f in \
  ponytail-activate.js \
  ponytail-mode-tracker.js \
  ponytail-subagent.js \
  ponytail-config.js \
  ponytail-runtime.js \
  ponytail-instructions.js \
  ponytail-statusline.sh \
  ponytail-statusline.ps1
do
  copy_hook "$PT_DIR/hooks" "$f"
done

# skills: from TOP-LEVEL skills/ (NOT .openclaw)
echo "  Copying skills..."
for skill in \
  ponytail \
  ponytail-audit \
  ponytail-debt \
  ponytail-gain \
  ponytail-help \
  ponytail-review
do
  copy_skill "$PT_DIR/skills" "$skill"
done

# commands: ponytail*.toml from upstream commands/
echo "  Copying commands (best-effort)..."
copy_commands_glob "$PT_DIR/commands" "ponytail*.toml"

# license
echo "  Copying license..."
cp "$PT_DIR/LICENSE" "$REPO/licenses/LICENSE-ponytail"

PONYTAIL_SHA="$(git -C "$PT_DIR" rev-parse HEAD)"
echo "  ponytail SHA: $PONYTAIL_SHA"
echo ""

# ---------------------------------------------------------------------------
# 2. caveman — https://github.com/JuliusBrussee/caveman
# ---------------------------------------------------------------------------

echo "============================================================"
echo "  [2/3] caveman"
echo "============================================================"

CAVEMAN_REF="${CAVEMAN_REF:-}"
clone_upstream "caveman" "https://github.com/JuliusBrussee/caveman" "$CAVEMAN_REF"

CM_DIR="$VENDOR_TMP/caveman"

# hooks: from upstream src/hooks/  (NOT root hooks/)
echo "  Copying hooks..."
for f in \
  caveman-activate.js \
  caveman-config.js \
  caveman-mode-tracker.js \
  caveman-statusline.sh \
  caveman-statusline.ps1
do
  copy_hook "$CM_DIR/src/hooks" "$f"
done

# skills: from TOP-LEVEL skills/
echo "  Copying skills..."
for skill in \
  caveman \
  caveman-commit \
  caveman-help \
  caveman-review \
  caveman-compress
do
  copy_skill "$CM_DIR/skills" "$skill"
done

# commands: caveman*.toml — best-effort (tolerate absence)
echo "  Copying commands (best-effort)..."
copy_commands_glob "$CM_DIR/commands" "caveman*.toml"

# license
echo "  Copying license..."
cp "$CM_DIR/LICENSE" "$REPO/licenses/LICENSE-caveman"

CAVEMAN_SHA="$(git -C "$CM_DIR" rev-parse HEAD)"
echo "  caveman SHA: $CAVEMAN_SHA"
echo ""

# ---------------------------------------------------------------------------
# 3. superpowers — https://github.com/obra/superpowers
# ---------------------------------------------------------------------------

echo "============================================================"
echo "  [3/3] superpowers"
echo "============================================================"

SUPERPOWERS_REF="${SUPERPOWERS_REF:-}"
clone_upstream "superpowers" "https://github.com/obra/superpowers" "$SUPERPOWERS_REF"

SP_DIR="$VENDOR_TMP/superpowers"

# skills: ALL of upstream skills/. — copy whole directory, flat
echo "  Copying skills (all)..."
# Iterate each immediate child of skills/ and copy recursively
for skill_path in "$SP_DIR/skills"/*/; do
  [[ -d "$skill_path" ]] || continue
  skill_name="$(basename "$skill_path")"
  copy_skill "$SP_DIR/skills" "$skill_name"
done

# hooks: everything in upstream hooks/ EXCEPT hooks.json
echo "  Copying hooks (excluding hooks.json)..."
for f in "$SP_DIR/hooks"/*; do
  [[ -f "$f" ]] || continue
  fname="$(basename "$f")"
  if [[ "$fname" == "hooks.json" ]]; then
    echo "    (skipping hooks.json)"
    continue
  fi
  echo "    hook: $fname"
  cp "$f" "$REPO/hooks/$fname"
done

# license
echo "  Copying license..."
cp "$SP_DIR/LICENSE" "$REPO/licenses/LICENSE-superpowers"

SUPERPOWERS_SHA="$(git -C "$SP_DIR" rev-parse HEAD)"
echo "  superpowers SHA: $SUPERPOWERS_SHA"
echo ""

# ---------------------------------------------------------------------------
# 4. Clean up .vendor-tmp/
# ---------------------------------------------------------------------------

echo "--> Cleaning up $VENDOR_TMP"

# Guard: only rm -rf if VENDOR_TMP is non-empty and is rooted inside REPO
if [[ -n "$VENDOR_TMP" && "$VENDOR_TMP" == "$REPO/.vendor-tmp" ]]; then
  rm -rf "$VENDOR_TMP"
  echo "    Removed $VENDOR_TMP"
else
  echo "    WARNING: VENDOR_TMP path looks unexpected ($VENDOR_TMP) — NOT removed. Delete manually."
fi
echo ""

# ---------------------------------------------------------------------------
# 5. Summary and reminder
# ---------------------------------------------------------------------------

cat <<SUMMARY
============================================================
  Vendor update complete
============================================================

  ponytail    $PONYTAIL_SHA
  caveman     $CAVEMAN_SHA
  superpowers $SUPERPOWERS_SHA

------------------------------------------------------------
  MANUAL STEPS REQUIRED
------------------------------------------------------------

  1. Bump the version in .claude-plugin/plugin.json if this
     is a release (patch/minor/major).

  2. Update the three pinned SHAs in THIRD_PARTY_NOTICES.md:
       ponytail    → $PONYTAIL_SHA
       caveman     → $CAVEMAN_SHA
       superpowers → $SUPERPOWERS_SHA

  3. Run the structure test:
       node --test tests/structure.test.mjs

  4. Commit the vendored changes:
       git add hooks/ skills/ commands/ licenses/ THIRD_PARTY_NOTICES.md .claude-plugin/plugin.json .gitignore
       git commit -m "chore: vendor update $(date +%Y-%m-%d)"

============================================================
SUMMARY
