#!/usr/bin/env bash
# =============================================================================
# local-install-claude-dev.sh — Maintainer-only Claude Code registry smoke test
# =============================================================================
#
# PURPOSE: Replicates Claude Code registry/cache entries so maintainers can
#          smoke-test local scwap changes before pushing. Public users should
#          install from README.md with /plugin marketplace add + /plugin install.
#          Safe and idempotent — re-running this script at any time is fine.
#
# WHAT THIS SCRIPT DOES:
#   1. Copies the repo to ~/.claude/plugins/marketplaces/scwap   (marketplace clone)
#   2. Copies the repo payload (no .git) to the versioned cache dir
#   3. Touches .in_use so Claude Code treats the cache entry as live
#   4. Edits known_marketplaces.json and installed_plugins.json via node
#
# WHAT THIS SCRIPT CANNOT DO (manual steps printed at end):
#   - Edit settings.json (integrity-guarded on this machine)
#   - Restart Claude Code
#
# REQUIREMENTS: bash, node, git, tar  (all present in Git Bash on this machine)
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# 0. Resolve paths
# ---------------------------------------------------------------------------

# REPO = directory containing this script's parent (repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$REPO/plugins/scwap"

PLUG="$HOME/.claude/plugins"

# 12-char short SHA of HEAD — used as the "version" in the cache path
SHA="$(git -C "$REPO" rev-parse --short=12 HEAD)"
# Full SHA for gitCommitSha field
SHA_FULL="$(git -C "$REPO" rev-parse HEAD)"

echo "==> scwap local-install"
echo "    repo  : $REPO"
echo "    plugin: $PLUGIN_ROOT"
echo "    SHA   : $SHA  (full: ${SHA_FULL:0:16}...)"
echo "    target: $PLUG"
echo ""

if [[ ! -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]]; then
  echo "ERROR: missing plugin manifest at $PLUGIN_ROOT/.claude-plugin/plugin.json" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Marketplace clone: $PLUG/marketplaces/scwap
#    The marketplace dir holds the raw repo so Claude Code can read the
#    marketplace.json and enumerate available plugins.
# ---------------------------------------------------------------------------

MKT="$PLUG/marketplaces/scwap"

if [[ -d "$MKT" ]]; then
  echo "--> Refreshing existing marketplace dir: $MKT"
  rm -rf "$MKT"
fi

echo "--> Copying repo to marketplace dir..."
mkdir -p "$MKT"
# Use tar pipe to keep it clean (excludes .git automatically via --exclude)
tar -C "$REPO" --exclude='.git' -cf - . | tar -C "$MKT" -xf -
echo "    Done: $MKT"
echo ""

# ---------------------------------------------------------------------------
# 2. Cache entry: $PLUG/cache/scwap/scwap/$SHA/
#    Layout mirrors existing entries (e.g. ponytail/ponytail/<sha>/).
#    Structure: <marketplace-name>/<plugin-name>/<version>/
#    The cache contains the installable plugin payload, not the repo root.
# ---------------------------------------------------------------------------

CACHE="$PLUG/cache/scwap/scwap/$SHA"

if [[ -d "$CACHE" ]]; then
  echo "--> Cache dir already exists for SHA=$SHA — refreshing..."
  rm -rf "$CACHE"
fi

echo "--> Copying plugin payload to cache dir..."
mkdir -p "$CACHE"
tar -C "$PLUGIN_ROOT" --exclude='.git' -cf - . | tar -C "$CACHE" -xf -

echo "--> Touching .in_use marker..."
touch "$CACHE/.in_use"

echo "    Done: $CACHE"
echo ""

# ---------------------------------------------------------------------------
# 3. Registry JSON mutations (idempotent, via node)
# ---------------------------------------------------------------------------

echo "--> Updating plugin registry JSON files..."

# Timestamps for this install run
ISO_NOW="$(node -e "process.stdout.write(new Date().toISOString())")"

# NOTE ON PATH FORMAT:
# Existing registry entries on this Windows machine use Windows-style paths
# (backslashes, e.g. "C:\\Users\\Jetsk\\..."). We derive the install paths from
# $MKT and $CACHE (POSIX in Git Bash), then convert to Windows backslash format
# using node so the entries match the format of every other installed plugin.
# If running on a pure-POSIX machine, the backslash conversion is a no-op safe
# no-op because forward slashes are also valid JSON string content there.

node - "$PLUG/known_marketplaces.json" "$PLUG/installed_plugins.json" \
      "$MKT" "$CACHE" "$SHA" "$SHA_FULL" "$ISO_NOW" <<'NODE_EOF'
const fs   = require('fs');
const path = require('path');

const [,, MKT_JSON, INST_JSON, mktPath, cachePath, sha, shaFull, isoNow] = process.argv;

// Helper: convert POSIX path to Windows backslash path
// (On a real Windows runtime the paths from Git Bash start with /c/Users/... or C:/Users/...)
function toWinPath(p) {
  // If it looks like a POSIX /c/Users/... path, convert to C:\Users\...
  const mingwRe = /^\/([a-zA-Z])\//;
  let win = p.replace(mingwRe, (_, drive) => drive.toUpperCase() + ':\\');
  // Replace remaining forward slashes with backslashes
  win = win.replace(/\//g, '\\');
  return win;
}

const mktWin   = toWinPath(mktPath);
const cacheWin = toWinPath(cachePath);

// ---- known_marketplaces.json ----------------------------------------
let km;
if (fs.existsSync(MKT_JSON)) {
  km = JSON.parse(fs.readFileSync(MKT_JSON, 'utf8'));
} else {
  // Minimal structure if file is missing (shouldn't happen on this machine)
  km = {};
}

km['scwap'] = {
  source: {
    source: 'github',
    repo:   'jetskicortez/scwap'
  },
  installLocation: mktWin,
  lastUpdated:     isoNow
};

fs.writeFileSync(MKT_JSON, JSON.stringify(km, null, 2) + '\n', 'utf8');
console.log('    written:', MKT_JSON);

// ---- installed_plugins.json ----------------------------------------
let inst;
if (fs.existsSync(INST_JSON)) {
  inst = JSON.parse(fs.readFileSync(INST_JSON, 'utf8'));
} else {
  // Minimal fallback structure matching the version:2 schema
  inst = { version: 2, plugins: {} };
}

// Ensure top-level shape is correct even if file was oddly formed
if (!inst.version)  inst.version  = 2;
if (!inst.plugins)  inst.plugins  = {};

// Overwrite the scwap@scwap entry (idempotent — always reflects current SHA)
inst.plugins['scwap@scwap'] = [
  {
    scope:        'user',
    installPath:  cacheWin,
    version:      sha,
    installedAt:  isoNow,
    lastUpdated:  isoNow,
    gitCommitSha: shaFull
  }
];

fs.writeFileSync(INST_JSON, JSON.stringify(inst, null, 2) + '\n', 'utf8');
console.log('    written:', INST_JSON);
NODE_EOF

echo ""

# ---------------------------------------------------------------------------
# 4. MANUAL STEPS — the script cannot do these
# ---------------------------------------------------------------------------

cat <<'MANUAL'
=============================================================================
MANUAL STEPS REQUIRED (Claude cannot do these — integrity guard + restart)
=============================================================================

Step 1: Enable the plugin in settings.json
  Open: ~/.claude/settings.json
  Find the "enabledPlugins" object and add:
    "scwap@scwap": true

  Full path on this machine:
    C:\Users\Jetsk\.claude\settings.json

Step 2: Re-hash the guard checksum (REQUIRED on this machine)
  settings.json is integrity-guarded. After editing, run in Git Bash:

    ~/.claude/hooks/update-guard-checksums.sh

  Without this step Claude Code will refuse to load the modified file.

Step 3: Restart Claude Code
  Close and reopen Claude Code completely (not just /clear).

Step 4: Verify the install
  - The status line should show [SP] (scwap active)
  - Run /scwap-flow — the skill should be available
  - If neither appears, run:  /plugins list  and confirm scwap@scwap is shown

=============================================================================
MANUAL

# ---------------------------------------------------------------------------
# 5. Done
# ---------------------------------------------------------------------------

echo "==> local-install complete.  SHA=$SHA"
echo "    marketplace : $MKT"
echo "    cache       : $CACHE"
echo ""
echo "    Complete the MANUAL STEPS above, then restart Claude Code."
