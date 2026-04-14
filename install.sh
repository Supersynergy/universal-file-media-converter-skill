#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  conv installer — Universal Media & File Converter (+ Skill)
#  https://github.com/Supersynergy/universal-media-file-converter
# ════════════════════════════════════════════════════════════════
set -euo pipefail

REPO="Supersynergy/universal-media-file-converter"
RAW="https://raw.githubusercontent.com/${REPO}/main"
INSTALL_DIR="${CONV_INSTALL_DIR:-$HOME/.local/share/conv}"
SKILL_DIR="${CONV_SKILL_DIR:-$HOME/.gg/skills}"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m✅\033[0m %s\n' "$*"; }
warn() { printf '\033[33m⚠\033[0m  %s\n' "$*"; }
err()  { printf '\033[31m❌\033[0m %s\n' "$*" >&2; }

bold "🔄 Installing Universal Media & File Converter…"
echo

if [ "$(uname)" != "Darwin" ]; then
  err "macOS only. Detected: $(uname)"; exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew not found. Install from https://brew.sh and re-run."; exit 1
fi
ok "Homebrew detected"

TOOLS=(ffmpeg vips gifski oxipng pngquant jpegoptim jpeg-xl libavif webp pandoc sox typst ab-av1 imagemagick mediainfo)
bold "📦 Installing tools (skips already-installed)…"
brew install "${TOOLS[@]}" 2>&1 | grep -E '(already|installed|Pouring|warning)' || true
ok "Tools installed"

mkdir -p "$INSTALL_DIR"
if curl -fsSL "$RAW/converter.sh" -o "$INSTALL_DIR/converter.sh"; then
  chmod +x "$INSTALL_DIR/converter.sh"
  ok "converter.sh → $INSTALL_DIR/converter.sh"
else
  err "Failed to download converter.sh"; exit 1
fi

if mkdir -p "$SKILL_DIR" 2>/dev/null; then
  curl -fsSL "$RAW/skill/universal-media-converter.md" -o "$SKILL_DIR/universal-media-converter.md" 2>/dev/null \
    && ok "Skill → $SKILL_DIR/universal-media-converter.md" \
    || warn "Skill not installed (optional, for Claude Code / GG Coder)"
fi

SHELL_RC=""
case "${SHELL:-}" in
  */zsh)  SHELL_RC="$HOME/.zshrc" ;;
  */bash) SHELL_RC="$HOME/.bashrc" ;;
esac

LINE="source \"$INSTALL_DIR/converter.sh\"  # universal-media-file-converter"
if [ -n "$SHELL_RC" ]; then
  if [ -f "$SHELL_RC" ] && grep -Fq "$LINE" "$SHELL_RC"; then
    ok "Already wired into $SHELL_RC"
  else
    echo "$LINE" >> "$SHELL_RC"
    ok "Added to $SHELL_RC"
  fi
else
  warn "Unknown shell. Add manually: $LINE"
fi

echo
bold "🎉 Done!"
echo "   Run: source ${SHELL_RC:-~/.zshrc} && conv_info"
echo "   Try: conv --help   |   conv --joke   |   conv --pet"
echo
echo "Uninstall any time:  curl -fsSL $RAW/uninstall.sh | bash"
