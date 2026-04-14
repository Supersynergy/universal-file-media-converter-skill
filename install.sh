#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# 🔄 Universal Mac Converter — Installer
# Installs all tools + adds shell functions to ~/.zshrc
# ═══════════════════════════════════════════════════════════
set -euo pipefail

BLUE='\033[0;34m' GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m' BOLD='\033[1m'

echo -e "${BLUE}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║  🔄 Universal Mac Converter — Installer  ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── Detect system ──
CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
NCPU=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
MEM_GB=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $0/1073741824}' || echo 8)
MACOS=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")

echo -e "  ${BOLD}System:${NC} $CHIP"
echo -e "  ${BOLD}Cores:${NC}  $NCPU"
echo -e "  ${BOLD}RAM:${NC}    ${MEM_GB}GB"
echo -e "  ${BOLD}macOS:${NC}  $MACOS"
echo ""

# ── Check Homebrew ──
if ! command -v brew &>/dev/null; then
  echo -e "${YELLOW}⚠️  Homebrew not found. Installing...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ── Install tools ──
echo -e "${BLUE}📦 Installing tools...${NC}"

TOOLS=(
  ffmpeg          # Video/Audio conversion + VideoToolbox
  imagemagick     # Universal image ops
  pandoc          # Document conversion (40+ formats)
  sox             # Audio effects
  mediainfo       # Media file analysis
  gifski          # High-quality GIF encoder
  oxipng          # Multi-threaded PNG optimizer
  pngquant        # Lossy PNG compression (90% smaller)
  jpegoptim       # JPEG optimizer (MozJPEG)
  vips            # Fast image processing (8x faster than ImageMagick)
  typst           # Fast PDF generation (100x faster than LaTeX)
  libavif         # AVIF encoder (50% smaller than JPEG)
  libjxl          # JPEG-XL encoder (98% compression)
  webp            # WebP encoder (Google native)
  ab-av1          # Auto-optimal video bitrate finder
  graphicsmagick  # Fast image processing alternative
)

OPTIONAL=(
  yt-dlp          # Video downloader
)

installed=0 skipped=0
for tool in "${TOOLS[@]}"; do
  if brew list "$tool" &>/dev/null 2>&1; then
    skipped=$((skipped+1))
  else
    echo -e "  ${GREEN}Installing${NC} $tool..."
    brew install "$tool" 2>/dev/null || echo -e "  ${YELLOW}⚠️  Failed to install $tool (non-critical)${NC}"
    installed=$((installed+1))
  fi
done

echo -e "\n  ✅ $installed installed, $skipped already present"

# ── Ask for optional tools ──
echo ""
echo -e "${YELLOW}Optional tools:${NC}"
for tool in "${OPTIONAL[@]}"; do
  if ! brew list "$tool" &>/dev/null 2>&1; then
    read -p "  Install $tool? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && brew install "$tool"
  fi
done

# ── Install shell functions ──
echo ""
echo -e "${BLUE}🔧 Installing shell functions...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNC_FILE="$SCRIPT_DIR/converter.sh"

# Check if already sourced in .zshrc
SHELL_RC="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.bashrc"

MARKER="# 🔄 Universal Mac Converter"

if grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
  echo -e "  ${YELLOW}Already in $SHELL_RC — updating source path${NC}"
  # Remove old entry and re-add
  sed -i '' "/$MARKER/d" "$SHELL_RC"
  sed -i '' '/universal-mac-converter/d' "$SHELL_RC"
fi

echo "" >> "$SHELL_RC"
echo "$MARKER" >> "$SHELL_RC"
echo "[ -f \"$FUNC_FILE\" ] && source \"$FUNC_FILE\"" >> "$SHELL_RC"

echo -e "  ✅ Added to $SHELL_RC"

# ── Verify installation ──
echo ""
echo -e "${BLUE}🔍 Verifying installation...${NC}"
ok=0 fail=0
for cmd in ffmpeg gifski oxipng pngquant jpegoptim vips cjxl avifenc cwebp ab-av1 typst pandoc sox magick gm sips mediainfo; do
  if command -v "$cmd" &>/dev/null; then
    ok=$((ok+1))
  else
    echo -e "  ${RED}❌ $cmd not found${NC}"
    fail=$((fail+1))
  fi
done
echo -e "  ✅ $ok tools verified, $fail missing"

# ── Done ──
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  ✅ Installation complete!               ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Restart your shell or run:${NC}"
echo -e "    source $SHELL_RC"
echo ""
echo -e "  ${BOLD}Then try:${NC}"
echo -e "    conv_info                    # Show your Mac profile"
echo -e "    conv input.mkv output.mp4    # Convert anything"
echo -e "    convall png webp             # Batch convert"
echo -e "    optall                       # Optimize all images"
echo ""
