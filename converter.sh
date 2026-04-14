#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  conv — Universal Media & File Converter (+ Skill)
#  One command. 16 tools. Zero config. Built on 55+ benchmarks.
#  https://github.com/Supersynergy/universal-media-file-converter
#  MIT License
# ════════════════════════════════════════════════════════════════

# Default exports so guards & info work even before init
: "${CONV_TIER:=}" "${CONV_NCPU:=}" "${CONV_PCPU:=}" "${CONV_MEM_GB:=}"
: "${CONV_VTB:=}" "${CONV_H264_BR:=}" "${CONV_H265_BR:=}"
: "${CONV_AV1_PRESET:=}" "${CONV_AVIF_SPEED:=}" "${CONV_JOBS:=}"
: "${CONV_OXIPNG_THREADS:=}" "${CONV_RAM:=}"
: "${CONV_STATS_FILE:=$HOME/.conv/stats}"
: "${CONV_SOUND:=1}"   # 0 to silence completion sound
: "${CONV_KONAMI:=0}"  # 1 forces Ultra profile

# ──────────────────────────────────────────────
#  System detection (runs once per shell)
# ──────────────────────────────────────────────
_conv_init() {
  [ -n "$CONV_TIER" ] && return

  local chip
  chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
  CONV_NCPU=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
  CONV_PCPU=$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null || echo "$CONV_NCPU")
  CONV_MEM_GB=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $0/1073741824}')
  [ -z "$CONV_MEM_GB" ] && CONV_MEM_GB=8

  if   [[ "$chip" == *Ultra* ]]; then CONV_TIER="ultra"
  elif [[ "$chip" == *Max*   ]]; then CONV_TIER="max"
  elif [[ "$chip" == *Pro*   ]]; then CONV_TIER="pro"
  elif [[ "$chip" =~ M[1-9]  ]]; then CONV_TIER="base"
  else                                CONV_TIER="intel"
  fi

  [ "$CONV_KONAMI" = "1" ] && CONV_TIER="ultra"

  if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q videotoolbox; then
    CONV_VTB=1
  else
    CONV_VTB=0
  fi

  case "$CONV_TIER" in
    ultra) CONV_H264_BR="6000k" CONV_H265_BR="5000k" CONV_AV1_PRESET="6"  CONV_AVIF_SPEED="4" CONV_JOBS="8" CONV_OXIPNG_THREADS="32" ;;
    max)   CONV_H264_BR="4000k" CONV_H265_BR="3000k" CONV_AV1_PRESET="8"  CONV_AVIF_SPEED="6" CONV_JOBS="6" CONV_OXIPNG_THREADS="16" ;;
    pro)   CONV_H264_BR="4000k" CONV_H265_BR="3000k" CONV_AV1_PRESET="8"  CONV_AVIF_SPEED="6" CONV_JOBS="4" CONV_OXIPNG_THREADS="12" ;;
    base)  CONV_H264_BR="3000k" CONV_H265_BR="2500k" CONV_AV1_PRESET="10" CONV_AVIF_SPEED="8" CONV_JOBS="2" CONV_OXIPNG_THREADS="8"  ;;
    intel) CONV_H264_BR=""      CONV_H265_BR=""      CONV_AV1_PRESET="12" CONV_AVIF_SPEED="9" CONV_JOBS="2" CONV_OXIPNG_THREADS="4"  ;;
  esac

  if   [ "$CONV_MEM_GB" -ge 64 ]; then CONV_RAM="high"
  elif [ "$CONV_MEM_GB" -ge 16 ]; then CONV_RAM="medium"
  else                                 CONV_RAM="low"
  fi

  export CONV_TIER CONV_NCPU CONV_PCPU CONV_MEM_GB CONV_VTB \
         CONV_H264_BR CONV_H265_BR CONV_AV1_PRESET CONV_AVIF_SPEED \
         CONV_JOBS CONV_OXIPNG_THREADS CONV_RAM
}

# ──────────────────────────────────────────────
#  Stats: persist lifetime bytes saved
# ──────────────────────────────────────────────
_conv_track() {
  local in_size="$1" out_size="$2"
  [ -z "$in_size" ] || [ -z "$out_size" ] && return
  mkdir -p "$(dirname "$CONV_STATS_FILE")"
  [ -f "$CONV_STATS_FILE" ] || echo "files=0 in=0 out=0" > "$CONV_STATS_FILE"
  # shellcheck disable=SC1090
  source "$CONV_STATS_FILE"
  files=$((${files:-0} + 1))
  in=$((${in:-0} + in_size))
  out=$((${out:-0} + out_size))
  printf 'files=%d\nin=%d\nout=%d\n' "$files" "$in" "$out" > "$CONV_STATS_FILE"
}

_conv_done() {
  local out="$1"
  [ -f "$out" ] || return
  if [ "$CONV_SOUND" = "1" ] && command -v afplay >/dev/null 2>&1; then
    (afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &)
  fi
  # Fortune of the day
  local stamp="$HOME/.conv/last_tip"
  local today; today=$(date +%Y-%m-%d)
  if [ ! -f "$stamp" ] || [ "$(cat "$stamp" 2>/dev/null)" != "$today" ]; then
    mkdir -p "$HOME/.conv" && echo "$today" > "$stamp"
    local tips=(
      "💡 Tip: 'conv --flex' shows your lifetime bytes saved."
      "💡 Tip: 'conv --joke' for an encoding koan."
      "💡 Tip: VideoToolbox without -b:v can bloat files 18×. Always set a bitrate."
      "💡 Tip: PNG → JXL gives ~98% compression (lossy q85)."
      "💡 Tip: For voice, MP3 V2 (~80 kbps) sounds identical to V0 (~245 kbps)."
      "💡 Tip: 'conv --pet' to meet Convy the Otter."
    )
    echo "${tips[$RANDOM % ${#tips[@]}]}"
  fi
}

# ──────────────────────────────────────────────
#  conv_info — show detected profile
# ──────────────────────────────────────────────
conv_info() {
  _conv_init
  cat <<EOF
🖥  Universal Media & File Converter — Adaptive Profile
   Chip:     $CONV_TIER ($(sysctl -n machdep.cpu.brand_string 2>/dev/null))
   Cores:    $CONV_NCPU ($CONV_PCPU performance)
   RAM:      ${CONV_MEM_GB} GB ($CONV_RAM)
   VTBox:    $([ "$CONV_VTB" = "1" ] && echo '✅ yes' || echo '❌ no (Intel/SW)')
   H.264:    ${CONV_H264_BR:-libx264 -crf 23}
   H.265:    ${CONV_H265_BR:-libx265 -crf 28}
   AV1:      preset $CONV_AV1_PRESET
   AVIF:     speed $CONV_AVIF_SPEED
   Parallel: $CONV_JOBS jobs
   oxipng:   $CONV_OXIPNG_THREADS threads
EOF
}

# ──────────────────────────────────────────────
#  Easter eggs 🥚
# ──────────────────────────────────────────────
_conv_joke() {
  local jokes=(
    "Why did the codec go to therapy?    Too many unresolved frames."
    "I told my WAV file a secret. It compressed to MP3 and lost half of it."
    "ProRes walks into a bar. The bar fills up."
    "What did the H.265 say to the H.264?    'I do more with less.'"
    "VP9: the only encoder slower than your code review."
    "AVIF, JXL, WebP and HEIC walk into a browser. Only one comes out."
  )
  echo "${jokes[$RANDOM % ${#jokes[@]}]}"
}

_conv_zen() {
  local koans=(
    "Lossless is a lie we tell ourselves."
    "The fastest encode is the one you didn't run."
    "Every bitrate is a compromise. Choose yours deliberately."
    "Speed × Quality × Size = constant. Pick two."
    "When in doubt: -c copy."
  )
  echo "🧘 ${koans[$RANDOM % ${#koans[@]}]}"
}

_conv_flex() {
  [ -f "$CONV_STATS_FILE" ] || { echo "No stats yet. Convert something first!"; return; }
  # shellcheck disable=SC1090
  source "$CONV_STATS_FILE"
  local saved=$((in - out))
  local pct=0
  [ "${in:-0}" -gt 0 ] && pct=$((saved * 100 / in))
  awk -v f="${files:-0}" -v i="${in:-0}" -v o="${out:-0}" -v s="$saved" -v p="$pct" 'BEGIN {
    printf "💪 Lifetime conv stats\n"
    printf "   Files converted: %d\n", f
    printf "   Bytes in:        %.2f MB\n", i/1048576
    printf "   Bytes out:       %.2f MB\n", o/1048576
    printf "   Saved:           %.2f MB  (%d%%)\n", s/1048576, p
  }'
}

_conv_roast() {
  local f="$1"
  [ -f "$f" ] || { echo "Nothing to roast. Give me a file."; return; }
  local size_mb
  size_mb=$(du -m "$f" 2>/dev/null | awk '{print $1}')
  local ext="${f##*.}"
  case "$ext" in
    png|PNG)  [ "${size_mb:-0}" -gt 5 ] && echo "🔥 ${size_mb}MB PNG? Your CDN is crying. Try: conv \"$f\" \"${f%.*}.jxl\"" || echo "🔥 PNG. The 1996 of formats." ;;
    jpg|JPG|jpeg|JPEG) echo "🔥 JPEG in $(date +%Y)? Bold. AVIF would be 56% smaller." ;;
    wav|WAV)  echo "🔥 ${size_mb}MB WAV. Are you mastering Abbey Road or just hoarding sine waves?" ;;
    mov|MOV)  echo "🔥 .mov — for when MP4 wasn't pretentious enough." ;;
    gif|GIF)  echo "🔥 GIF. The format your aunt forwards in emails." ;;
    *)        echo "🔥 .$ext — I don't even know how to roast that. Brave choice." ;;
  esac
}

_conv_pet() {
  _conv_init
  [ -f "$CONV_STATS_FILE" ] && source "$CONV_STATS_FILE"
  local age=${files:-0}
  local mood="🥺"
  [ "$age" -gt 10 ]   && mood="🙂"
  [ "$age" -gt 100 ]  && mood="😎"
  [ "$age" -gt 1000 ] && mood="🦾"
  cat <<EOF
       .--.
      ( $mood )    Convy the Otter
       \\__/     "I've helped you convert $age files."
      /|  |\\    Tier: $CONV_TIER
     d  ||  b
EOF
}

_conv_help() {
  cat <<'EOF'
conv — Universal Media & File Converter

USAGE
  conv <input> <output>          Convert any file to any format (auto-detect tool)
  conv_info                      Show detected hardware profile
  convall <src-ext> <dst-ext>    Batch convert all files in cwd
  optimg <files...>              Optimize PNG/JPG in place
  optall                         Parallel optimize all images recursively
  smartencode <video> [q]        q = low|med|high|lossless|auto
  resize <image> <width> [out]   vips/sips depending on RAM

EASTER EGGS 🥚
  conv --joke         Random encoding joke
  conv --zen          Encoding koan
  conv --flex         Lifetime bytes-saved stats
  conv --roast <f>    Roast your unoptimized file
  conv --pet          Meet Convy the Otter
  conv --konami       Force Ultra profile (set CONV_KONAMI=1)
  conv --help         This screen

ENV
  CONV_SOUND=0        Disable completion sound
  CONV_KONAMI=1       Force Ultra profile on any Mac
EOF
}

# ──────────────────────────────────────────────
#  Main: conv <input> <output>
# ──────────────────────────────────────────────
conv() {
  _conv_init

  # Easter eggs / flags
  case "$1" in
    -h|--help)    _conv_help; return 0 ;;
    --joke)       _conv_joke; return 0 ;;
    --zen)        _conv_zen;  return 0 ;;
    --flex)       _conv_flex; return 0 ;;
    --roast)      _conv_roast "$2"; return 0 ;;
    --pet)        _conv_pet;  return 0 ;;
    --konami)     CONV_KONAMI=1; CONV_TIER=""; _conv_init; echo "🎮 Ultra mode unlocked."; conv_info; return 0 ;;
    --info)       conv_info; return 0 ;;
    --version)    echo "conv v5.0 — Universal Media & File Converter"; return 0 ;;
  esac

  local input="$1" output="$2"
  if [ -z "$input" ] || [ -z "$output" ]; then
    _conv_help; return 1
  fi
  if [ ! -f "$input" ]; then
    echo "❌ File not found: $input" >&2; return 1
  fi

  local in_ext="${input##*.}" out_ext="${output##*.}"
  in_ext=$(printf '%s' "$in_ext" | tr '[:upper:]' '[:lower:]')
  out_ext=$(printf '%s' "$out_ext" | tr '[:upper:]' '[:lower:]')

  local video_exts=" mp4 mkv avi mov wmv flv webm m4v mpg mpeg ts vob 3gp "
  local audio_exts=" mp3 wav flac aac m4a ogg opus wma aiff alac "
  local image_exts=" jpg jpeg png gif bmp tiff tif webp heic heif svg ico avif jxl "
  local doc_exts=" md html pdf docx epub rst tex txt rtf odt pptx typ "
  _is() { [[ "$1" == *" $2 "* ]]; }

  local in_size out_size
  in_size=$(stat -f%z "$input" 2>/dev/null || echo 0)

  # ── VIDEO → GIF ──
  if _is "$video_exts" "$in_ext" && [ "$out_ext" = "gif" ]; then
    if command -v gifski >/dev/null 2>&1 && [ "$CONV_MEM_GB" -ge 8 ]; then
      echo "🎬 → GIF (gifski, $CONV_TIER)"
      local t; t=$(mktemp -d)
      ffmpeg -y -i "$input" -vf "fps=15,scale=480:-1" "$t/f%04d.png" 2>/dev/null
      gifski -o "$output" --fps 15 --quality 90 --width 480 "$t"/f*.png
      rm -rf "$t"
    else
      echo "🎬 → GIF (ffmpeg, low-RAM)"
      ffmpeg -y -i "$input" -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$output"
    fi

  # ── VIDEO ──
  elif _is "$video_exts" "$in_ext" || _is "$video_exts" "$out_ext"; then
    local vc ac
    vc=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$input" 2>/dev/null)
    ac=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$input" 2>/dev/null)
    case "$out_ext" in
      mp4|m4v)
        if [ "$vc" = "h264" ] && { [ "$ac" = "aac" ] || [ "$ac" = "mp3" ] || [ -z "$ac" ]; }; then
          echo "🎬 → MP4 (copy, INSTANT!)"
          ffmpeg -y -i "$input" -c copy -movflags +faststart "$output"
        elif [ "$CONV_VTB" = "1" ]; then
          echo "🎬 → MP4 (VTBox H.264 @ ${CONV_H264_BR}, $CONV_TIER)"
          ffmpeg -y -i "$input" -c:v h264_videotoolbox -b:v "$CONV_H264_BR" -c:a aac -b:a 256k -movflags +faststart "$output"
        else
          echo "🎬 → MP4 (libx264 crf23, Intel/SW)"
          ffmpeg -y -i "$input" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 256k -movflags +faststart "$output"
        fi ;;
      mkv)
        if [ "$CONV_VTB" = "1" ]; then
          echo "🎬 → MKV (VTBox HEVC @ ${CONV_H265_BR})"
          ffmpeg -y -i "$input" -c:v hevc_videotoolbox -b:v "$CONV_H265_BR" -c:a aac -b:a 256k "$output"
        else
          echo "🎬 → MKV (libx265 crf28)"
          ffmpeg -y -i "$input" -c:v libx265 -crf 28 -preset medium -c:a aac -b:a 256k "$output"
        fi ;;
      webm)
        echo "🎬 → WebM (VP9, slow!)"
        ffmpeg -y -i "$input" -c:v libvpx-vp9 -b:v 2M -c:a libopus "$output" ;;
      mov)
        if [ "$CONV_VTB" = "1" ] && [ "$CONV_TIER" != "intel" ]; then
          echo "🎬 → MOV (ProRes VTBox)"
          ffmpeg -y -i "$input" -c:v prores_videotoolbox -profile:v 3 -c:a pcm_s16le "$output"
        else
          echo "🎬 → MOV (ProRes SW)"
          ffmpeg -y -i "$input" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "$output"
        fi ;;
      *) ffmpeg -y -i "$input" "$output" ;;
    esac

  # ── AUDIO ──
  elif _is "$audio_exts" "$in_ext" || _is "$audio_exts" "$out_ext"; then
    case "$out_ext" in
      mp3)  echo "🎵 → MP3";  ffmpeg -y -i "$input" -c:a libmp3lame -q:a 2 "$output" ;;
      flac) echo "🎵 → FLAC"; ffmpeg -y -i "$input" -c:a flac "$output" ;;
      m4a)  echo "🎵 → AAC";  ffmpeg -y -i "$input" -c:a aac -b:a 256k "$output" ;;
      opus) echo "🎵 → Opus"; ffmpeg -y -i "$input" -c:a libopus -b:a 128k "$output" ;;
      wav)  echo "🎵 → WAV";  ffmpeg -y -i "$input" -c:a pcm_s16le "$output" ;;
      *)    ffmpeg -y -i "$input" "$output" ;;
    esac

  # ── IMAGES ──
  elif _is "$image_exts" "$in_ext" || _is "$image_exts" "$out_ext"; then
    case "$out_ext" in
      webp)
        echo "🖼  → WebP"
        if command -v cwebp >/dev/null 2>&1; then cwebp -q 80 "$input" -o "$output"
        else magick "$input" -quality 80 "$output"; fi ;;
      avif)
        echo "🖼  → AVIF (speed $CONV_AVIF_SPEED)"
        if command -v avifenc >/dev/null 2>&1; then avifenc "$input" "$output" --speed "$CONV_AVIF_SPEED"
        else magick "$input" "$output"; fi ;;
      jxl)
        echo "🖼  → JXL"
        if command -v cjxl >/dev/null 2>&1; then
          if [ "$in_ext" = "jpg" ] || [ "$in_ext" = "jpeg" ]; then
            cjxl "$input" "$output" -q 100
          else
            cjxl "$input" "$output" -q 85
          fi
        else
          echo "❌ cjxl missing: brew install jpeg-xl" >&2; return 1
        fi ;;
      jpg|jpeg)
        if [ "$in_ext" = "heic" ] || [ "$in_ext" = "heif" ]; then
          echo "🖼  → JPEG (sips, native HEIC)"
          sips -s format jpeg "$input" --out "$output" >/dev/null
        else
          echo "🖼  → JPEG"
          magick "$input" -quality 85 "$output"
        fi ;;
      png)
        echo "🖼  → PNG"
        magick "$input" "$output"
        command -v pngquant >/dev/null 2>&1 && pngquant --quality=65-80 --ext .png --force "$output" 2>/dev/null ;;
      *) magick "$input" "$output" ;;
    esac

  # ── DOCUMENTS ──
  elif _is "$doc_exts" "$in_ext" || _is "$doc_exts" "$out_ext"; then
    if [ "$in_ext" = "typ" ] && [ "$out_ext" = "pdf" ] && command -v typst >/dev/null 2>&1; then
      echo "📄 → PDF (typst)"; typst compile "$input" "$output"
    elif [ "$out_ext" = "pdf" ] && [ "$in_ext" = "md" ] && command -v typst >/dev/null 2>&1; then
      echo "📄 → PDF (pandoc + typst)"; pandoc "$input" -o "$output" --pdf-engine=typst
    else
      echo "📄 → $out_ext (pandoc)"; pandoc "$input" -o "$output"
    fi
  else
    echo "❓ Auto-detect…"
    ffmpeg -y -i "$input" "$output" 2>/dev/null \
      || magick "$input" "$output" 2>/dev/null \
      || pandoc "$input" -o "$output"
  fi

  out_size=$(stat -f%z "$output" 2>/dev/null || echo 0)
  _conv_track "$in_size" "$out_size"
  _conv_done "$output"
}

# ──────────────────────────────────────────────
#  convall — batch in cwd, NUL-safe, parallel
# ──────────────────────────────────────────────
convall() {
  _conv_init
  local src="$1" dst="$2"
  [ -z "$src" ] || [ -z "$dst" ] && { echo "Usage: convall <src-ext> <dst-ext>"; return 1; }
  local count=0
  while IFS= read -r -d '' f; do
    count=$((count + 1))
    conv "$f" "${f%.*}.$dst"
  done < <(find . -maxdepth 1 -type f -iname "*.$src" -print0)
  echo "✅ Converted $count files."
}

# ──────────────────────────────────────────────
#  optimg — optimise listed PNG/JPG in place
# ──────────────────────────────────────────────
optimg() {
  _conv_init
  local f
  for f in "$@"; do
    [ -f "$f" ] || continue
    case "${f##*.}" in
      png|PNG)            pngquant --quality=65-80 --ext .png --force "$f" 2>/dev/null && echo "✅ $f" ;;
      jpg|jpeg|JPG|JPEG)  jpegoptim --strip-all --max=85 "$f" >/dev/null && echo "✅ $f" ;;
    esac
  done
}

# ──────────────────────────────────────────────
#  optall — recursive parallel optimisation (NUL-safe)
# ──────────────────────────────────────────────
optall() {
  _conv_init
  echo "⚡ Optimising all images recursively ($CONV_TIER, $CONV_NCPU cores)…"
  if ! command -v pngquant >/dev/null 2>&1 || ! command -v jpegoptim >/dev/null 2>&1; then
    echo "❌ Need pngquant + jpegoptim. Run: brew install pngquant jpegoptim" >&2
    return 1
  fi
  find . -type f \( -iname '*.png' \) -print0 \
    | xargs -0 -P "$CONV_NCPU" -n 1 pngquant --quality=65-80 --ext .png --force 2>/dev/null
  find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 \
    | xargs -0 -P "$CONV_NCPU" -n 1 jpegoptim --strip-all --max=85 >/dev/null
  echo "✅ Done."
}

# ──────────────────────────────────────────────
#  smartencode — smart video encoder w/ presets
# ──────────────────────────────────────────────
smartencode() {
  _conv_init
  local input="$1" q="${2:-med}" output="${1%.*}_encoded.mp4"
  [ -f "$input" ] || { echo "❌ File not found: $input" >&2; return 1; }

  if [ "$CONV_VTB" = "1" ]; then
    case "$q" in
      low)      ffmpeg -y -i "$input" -c:v h264_videotoolbox -b:v 1500k -c:a aac -b:a 128k -movflags +faststart "$output" ;;
      med)      ffmpeg -y -i "$input" -c:v hevc_videotoolbox -b:v "$CONV_H265_BR" -c:a aac -b:a 256k -movflags +faststart "$output" ;;
      high)     ffmpeg -y -i "$input" -c:v hevc_videotoolbox -b:v 8000k -c:a aac -b:a 320k -movflags +faststart "$output" ;;
      lossless) output="${1%.*}_lossless.mov"
                ffmpeg -y -i "$input" -c:v prores_videotoolbox -profile:v 3 -c:a pcm_s16le "$output" ;;
      auto)     command -v ab-av1 >/dev/null 2>&1 || { echo "Install: brew install ab-av1"; return 1; }
                ab-av1 auto-encode -i "$input" -e hevc_videotoolbox --min-vmaf 95; return ;;
      *) echo "Usage: smartencode <video> [low|med|high|lossless|auto]"; return 1 ;;
    esac
  else
    case "$q" in
      low)      ffmpeg -y -i "$input" -c:v libx264 -crf 28 -preset fast   -c:a aac -b:a 128k -movflags +faststart "$output" ;;
      med)      ffmpeg -y -i "$input" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 256k -movflags +faststart "$output" ;;
      high)     ffmpeg -y -i "$input" -c:v libx265 -crf 22 -preset slow   -c:a aac -b:a 320k "$output" ;;
      lossless) output="${1%.*}_lossless.mov"
                ffmpeg -y -i "$input" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "$output" ;;
      auto)     command -v ab-av1 >/dev/null 2>&1 || { echo "Install: brew install ab-av1"; return 1; }
                ab-av1 auto-encode -i "$input" -e libx264 --min-vmaf 95; return ;;
    esac
  fi
  echo "✅ → $output"
  _conv_done "$output"
}

# ──────────────────────────────────────────────
#  resize — adaptive: vips (RAM) or sips
# ──────────────────────────────────────────────
resize() {
  _conv_init
  local input="$1" width="${2:-800}"
  local output="${3:-${input%.*}_${width}px.${input##*.}}"
  [ -f "$input" ] || { echo "❌ File not found: $input" >&2; return 1; }
  if { [ "$CONV_RAM" = "high" ] || [ "$CONV_RAM" = "medium" ]; } && command -v vips >/dev/null 2>&1; then
    echo "🖼  Resize (vips, $CONV_RAM RAM)"
    vips thumbnail "$input" "$output" "$width"
  else
    echo "🖼  Resize (sips, low-RAM)"
    sips --resampleWidth "$width" "$input" --out "$output" >/dev/null
  fi
  echo "✅ → $output"
}
