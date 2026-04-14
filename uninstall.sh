#!/usr/bin/env bash
# Uninstall conv — Universal Media & File Converter
set -euo pipefail

INSTALL_DIR="${CONV_INSTALL_DIR:-$HOME/.local/share/conv}"
SKILL_FILE="$HOME/.gg/skills/universal-media-converter.md"
STATS_DIR="$HOME/.conv"

echo "🗑  Uninstalling conv…"

rm -rf "$INSTALL_DIR" && echo "  ✅ Removed $INSTALL_DIR"
[ -f "$SKILL_FILE" ] && rm -f "$SKILL_FILE" && echo "  ✅ Removed skill"

for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  if grep -q 'universal-media-file-converter' "$rc"; then
    cp "$rc" "$rc.conv-bak"
    grep -v 'universal-media-file-converter' "$rc.conv-bak" > "$rc"
    echo "  ✅ Cleaned $rc (backup: $rc.conv-bak)"
  fi
done

read -r -p "Also delete lifetime stats at $STATS_DIR? [y/N] " ans
if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
  rm -rf "$STATS_DIR" && echo "  ✅ Stats removed"
fi

echo "👋 Done. Tools (ffmpeg, vips…) are left alone — remove with brew if you want."
