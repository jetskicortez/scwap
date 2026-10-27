#!/usr/bin/env bash
# scwap unified statusline: [SP] + ponytail badge + caveman badge.
# Reuses the vendored per-plugin statusline scripts (each reads its own flag file).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="\033[38;5;110m[SP]\033[0m"
input=""; [ -t 0 ] || IFS= read -r -d '' -t 1 input || true  # Claude Code sends session JSON (session_id) on stdin once; replay it to each badge script
pony="$(printf '%s' "$input" | bash "$DIR/ponytail-statusline.sh" 2>/dev/null)"; [ -n "$pony" ] && out="$out  $pony"
cave="$(printf '%s' "$input" | bash "$DIR/caveman-statusline.sh" 2>/dev/null)"; [ -n "$cave" ] && out="$out  $cave"
printf "%b" "$out"
