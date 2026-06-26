#!/usr/bin/env bash
# scwap unified statusline: [SP] + ponytail badge + caveman badge.
# Reuses the vendored per-plugin statusline scripts (each reads its own flag file).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="\033[38;5;110m[SP]\033[0m"
pony="$(bash "$DIR/ponytail-statusline.sh" 2>/dev/null)"; [ -n "$pony" ] && out="$out  $pony"
cave="$(bash "$DIR/caveman-statusline.sh" 2>/dev/null)"; [ -n "$cave" ] && out="$out  $cave"
printf "%b" "$out"
