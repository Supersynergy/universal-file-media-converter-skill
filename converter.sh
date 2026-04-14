#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# 🔄 Universal Mac Converter v5 — Shell Functions
# Adaptive to all Macs: M1→M4 Ultra + Intel
# https://github.com/Supersynergy/universal-mac-converter
# ═══════════════════════════════════════════════════════════

# ════════════════════════════════════════════════════════════════
# UNIVERSAL CONVERTER v5 — Adaptiv für alle Macs
# ════════════════════════════════════════════════════════════════

# System einmalig erkennen (bei Shell-Start)
_conv_init() {
  [ -n "$CONV_TIER" ] && return  # Bereits initialisiert

  local chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
  export CONV_NCPU=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
  export CONV_PCPU=$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null || echo "$CONV_NCPU")
  export CONV_MEM_GB=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $0/1073741824}' || echo 8)

  # Tier
  if [[ "$chip" == *"Ultra"* ]]; then
    export CONV_TIER="ultra"
  elif [[ "$chip" == *"Max"* ]]; then
    export CONV_TIER="max"
  elif [[ "$chip" == *"Pro"* ]]; then
    export CONV_TIER="pro"
  elif [[ "$chip" == *"M1"* || "$chip" == *"M2"* || "$chip" == *"M3"* || "$chip" == *"M4"* ]]; then
    export CONV_TIER="base"
  else
    export CONV_TIER="intel"
  fi

  # VideoToolbox?
  ffmpeg -hide_banner -encoders 2>/dev/null | grep -q videotoolbox && export CONV_VTB=1 || export CONV_VTB=0

  # Adaptive Parameter setzen
  case "$CONV_TIER" in
    ultra)
      export CONV_H264_BR="6000k" CONV_H265_BR="5000k" CONV_AV1_PRESET="6"
      export CONV_AVIF_SPEED="4" CONV_JOBS="8" CONV_OXIPNG_THREADS="32" ;;
    max)
      export CONV_H264_BR="4000k" CONV_H265_BR="3000k" CONV_AV1_PRESET="8"
      export CONV_AVIF_SPEED="6" CONV_JOBS="6" CONV_OXIPNG_THREADS="16" ;;
    pro)
      export CONV_H264_BR="4000k" CONV_H265_BR="3000k" CONV_AV1_PRESET="8"
      export CONV_AVIF_SPEED="6" CONV_JOBS="4" CONV_OXIPNG_THREADS="12" ;;
    base)
      export CONV_H264_BR="3000k" CONV_H265_BR="2500k" CONV_AV1_PRESET="10"
      export CONV_AVIF_SPEED="8" CONV_JOBS="2" CONV_OXIPNG_THREADS="8" ;;
    intel)
      export CONV_H264_BR="" CONV_H265_BR="" CONV_AV1_PRESET="12"
      export CONV_AVIF_SPEED="9" CONV_JOBS="2" CONV_OXIPNG_THREADS="4" ;;
  esac

  # RAM-Profil
  [ "$CONV_MEM_GB" -ge 64 ] && export CONV_RAM="high" || { [ "$CONV_MEM_GB" -ge 16 ] && export CONV_RAM="medium" || export CONV_RAM="low"; }
}

# Info anzeigen
conv_info() {
  _conv_init
  echo "🖥️  Mac Converter v5 — Adaptives Profil"
  echo "   Chip:     $CONV_TIER ($(sysctl -n machdep.cpu.brand_string 2>/dev/null))"
  echo "   Kerne:    $CONV_NCPU ($CONV_PCPU Performance)"
  echo "   RAM:      ${CONV_MEM_GB}GB ($CONV_RAM)"
  echo "   VTBox:    $([[ $CONV_VTB == 1 ]] && echo '✅ Ja' || echo '❌ Nein (Intel)')"
  echo "   H.264:    ${CONV_H264_BR:-'libx264 -crf 23'}"
  echo "   H.265:    ${CONV_H265_BR:-'libx265 -crf 28'}"
  echo "   AV1:      preset $CONV_AV1_PRESET"
  echo "   AVIF:     speed $CONV_AVIF_SPEED"
  echo "   Parallel: $CONV_JOBS jobs"
  echo "   oxipng:   $CONV_OXIPNG_THREADS threads"
}

# ════════════════════════════════════════
# HAUPTFUNKTION: conv <input> <output>
# ════════════════════════════════════════
conv() {
  _conv_init
  local input="$1" output="$2"
  [ -z "$input" ] || [ -z "$output" ] && { echo "Usage: conv <input> <output>"; return 1; }
  [ ! -f "$input" ] && { echo "❌ Datei nicht gefunden: $input"; return 1; }

  local in_ext="${input##*.}" out_ext="${output##*.}"
  in_ext=$(echo "$in_ext" | tr '[:upper:]' '[:lower:]')
  out_ext=$(echo "$out_ext" | tr '[:upper:]' '[:lower:]')

  local video_exts="mp4 mkv avi mov wmv flv webm m4v mpg mpeg ts vob 3gp"
  local audio_exts="mp3 wav flac aac m4a ogg opus wma aiff alac"
  local image_exts="jpg jpeg png gif bmp tiff tif webp heic heif svg ico avif jxl"
  local doc_exts="md html pdf docx epub rst tex txt rtf odt pptx typ"
  _is() { echo "$1" | grep -qw "$2"; }

  # ── VIDEO → GIF ──
  if _is "$video_exts" "$in_ext" && [[ "$out_ext" == "gif" ]]; then
    if command -v gifski &>/dev/null && [ "$CONV_MEM_GB" -ge 8 ]; then
      echo "🎬 → GIF (gifski, $CONV_TIER)"; local t=$(mktemp -d)
      ffmpeg -y -i "$input" -vf "fps=15,scale=480:-1" "$t/f%04d.png" 2>/dev/null
      gifski -o "$output" --fps 15 --quality 90 --width 480 "$t"/f*.png; rm -rf "$t"
    else
      echo "🎬 → GIF (ffmpeg, RAM-schonend)"
      ffmpeg -y -i "$input" -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$output"
    fi

  # ── VIDEO ──
  elif _is "$video_exts" "$in_ext" || _is "$video_exts" "$out_ext"; then
    local vc=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$input" 2>/dev/null)
    local ac=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$input" 2>/dev/null)

    case "$out_ext" in
      mp4|m4v)
        # Prüfe ob Container-Copy möglich
        if [[ "$vc" == "h264" && ("$ac" == "aac" || "$ac" == "mp3" || -z "$ac") ]]; then
          echo "🎬 → MP4 (copy, INSTANT!)"; ffmpeg -y -i "$input" -c copy -movflags +faststart "$output"
        elif [[ "$CONV_VTB" == "1" ]]; then
          echo "🎬 → MP4 (VTBox H.264, $CONV_TIER, ${CONV_H264_BR})"
          ffmpeg -y -i "$input" -c:v h264_videotoolbox -b:v "$CONV_H264_BR" -c:a aac -b:a 256k -movflags +faststart "$output"
        else
          echo "🎬 → MP4 (x264, Intel-Modus)"
          ffmpeg -y -i "$input" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 256k -movflags +faststart "$output"
        fi ;;
      mkv)
        if [[ "$CONV_VTB" == "1" ]]; then
          echo "🎬 → MKV (VTBox HEVC, ${CONV_H265_BR})"; ffmpeg -y -i "$input" -c:v hevc_videotoolbox -b:v "$CONV_H265_BR" -c:a aac -b:a 256k "$output"
        else
          echo "🎬 → MKV (x265)"; ffmpeg -y -i "$input" -c:v libx265 -crf 28 -preset medium -c:a aac -b:a 256k "$output"
        fi ;;
      webm) echo "🎬 → WebM (VP9, LANGSAM!)"; ffmpeg -y -i "$input" -c:v libvpx-vp9 -b:v 2M -c:a libopus "$output" ;;
      mov)
        if [[ "$CONV_TIER" != "intel" && "$CONV_TIER" != "base" ]] || [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" != *"M1" ]]; then
          echo "🎬 → MOV (ProRes VTBox)"; ffmpeg -y -i "$input" -c:v prores_videotoolbox -profile:v 3 -c:a pcm_s16le "$output"
        else
          echo "🎬 → MOV (ProRes Software)"; ffmpeg -y -i "$input" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "$output"
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

  # ── BILDER ──
  elif _is "$image_exts" "$in_ext" || _is "$image_exts" "$out_ext"; then
    case "$out_ext" in
      webp)
        echo "🖼️ → WebP"; command -v cwebp &>/dev/null && cwebp -q 80 "$input" -o "$output" || magick "$input" -quality 80 "$output" ;;
      avif)
        echo "🖼️ → AVIF (speed $CONV_AVIF_SPEED)"
        command -v avifenc &>/dev/null && avifenc "$input" "$output" --speed "$CONV_AVIF_SPEED" || magick "$input" "$output" ;;
      jxl)
        echo "🖼️ → JXL"
        if command -v cjxl &>/dev/null; then
          if [[ "$in_ext" == "jpg" || "$in_ext" == "jpeg" ]]; then
            cjxl "$input" "$output" -q 100  # Lossless JPEG recomp
          else
            cjxl "$input" "$output" -q 85   # Lossy für PNG etc.
          fi
        else
          echo "❌ cjxl nicht installiert: brew install libjxl"
        fi ;;
      jpg|jpeg)
        if [[ "$in_ext" == "heic" || "$in_ext" == "heif" ]]; then
          echo "🖼️ → JPEG (sips nativ)"; sips -s format jpeg "$input" --out "$output"
        else
          echo "🖼️ → JPEG"; magick "$input" -quality 85 "$output"
        fi ;;
      png)
        echo "🖼️ → PNG"; magick "$input" "$output"
        command -v pngquant &>/dev/null && pngquant --quality=65-80 --ext .png --force "$output" 2>/dev/null ;;
      *) magick "$input" "$output" ;;
    esac

  # ── DOKUMENTE ──
  elif _is "$doc_exts" "$in_ext" || _is "$doc_exts" "$out_ext"; then
    if [[ "$in_ext" == "typ" && "$out_ext" == "pdf" ]] && command -v typst &>/dev/null; then
      echo "📄 → PDF (typst)"; typst compile "$input" "$output"
    elif [[ "$out_ext" == "pdf" && "$in_ext" == "md" ]] && command -v typst &>/dev/null; then
      echo "📄 → PDF (pandoc+typst)"; pandoc "$input" -o "$output" --pdf-engine=typst
    else
      echo "📄 → $out_ext (pandoc)"; pandoc "$input" -o "$output"
    fi
  else
    echo "❓ Auto-detect..."
    ffmpeg -y -i "$input" "$output" 2>/dev/null || magick "$input" "$output" 2>/dev/null || pandoc "$input" -o "$output"
  fi
}

# BATCH: convall <src-ext> <dst-ext>
convall() {
  _conv_init
  local src="$1" dst="$2" count=$(ls *."$1" 2>/dev/null | wc -l | tr -d ' ')
  echo "🔄 Konvertiere $count .$src → .$dst ($CONV_TIER, ${CONV_NCPU} Kerne)..."
  for f in *."$src"; do [ -f "$f" ] && conv "$f" "${f%.$src}.$dst"; done
  echo "✅ Fertig!"
}

# OPTIMIZE: optimg *.png *.jpg
optimg() {
  _conv_init
  for f in "$@"; do
    case "${f##*.}" in
      png|PNG) pngquant --quality=65-80 --ext .png --force "$f" 2>/dev/null; echo "✅ $f" ;;
      jpg|jpeg|JPG|JPEG) jpegoptim --strip-all --max=85 "$f"; echo "✅ $f" ;;
    esac
  done
}

# OPTIMIZE ALL (parallel, adaptiv)
optall() {
  _conv_init
  echo "⚡ Optimiere alle Bilder ($CONV_TIER, $CONV_NCPU Kerne)..."
  fd -e png | xargs -P "$CONV_NCPU" -I{} pngquant --quality=65-80 --ext .png --force {} 2>/dev/null
  fd -e jpg -e jpeg | xargs -P "$CONV_NCPU" jpegoptim --strip-all --max=85
  echo "✅ Fertig!"
}

# SMART VIDEO: smartencode <input> [low|med|high|lossless|auto]
smartencode() {
  _conv_init
  local input="$1" q="${2:-med}" output="${1%.*}_encoded.mp4"

  if [[ "$CONV_VTB" == "1" ]]; then
    case "$q" in
      low)      ffmpeg -y -i "$input" -c:v h264_videotoolbox -b:v 1500k -c:a aac -b:a 128k -movflags +faststart "$output" ;;
      med)      ffmpeg -y -i "$input" -c:v hevc_videotoolbox -b:v "$CONV_H265_BR" -c:a aac -b:a 256k -movflags +faststart "$output" ;;
      high)     ffmpeg -y -i "$input" -c:v hevc_videotoolbox -b:v 8000k -c:a aac -b:a 320k -movflags +faststart "$output" ;;
      lossless) output="${1%.*}_lossless.mov"; ffmpeg -y -i "$input" -c:v prores_videotoolbox -profile:v 3 -c:a pcm_s16le "$output" ;;
      auto)     ab-av1 auto-encode -i "$input" -e hevc_videotoolbox --min-vmaf 95; return ;;
    esac
  else
    case "$q" in
      low)      ffmpeg -y -i "$input" -c:v libx264 -crf 28 -preset fast -c:a aac -b:a 128k -movflags +faststart "$output" ;;
      med)      ffmpeg -y -i "$input" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 256k -movflags +faststart "$output" ;;
      high)     ffmpeg -y -i "$input" -c:v libx265 -crf 22 -preset slow -c:a aac -b:a 320k "$output" ;;
      lossless) output="${1%.*}_lossless.mov"; ffmpeg -y -i "$input" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "$output" ;;
      auto)     ab-av1 auto-encode -i "$input" -e libx264 --min-vmaf 95; return ;;
    esac
  fi
  echo "✅ → $output"
}

# RESIZE (adaptiv: vips für viel RAM, sips für wenig)
resize() {
  _conv_init
  local input="$1" width="${2:-800}" output="${3:-${1%.*}_${2:-800}px.${1##*.}}"
  if [[ "$CONV_RAM" == "high" || "$CONV_RAM" == "medium" ]] && command -v vips &>/dev/null; then
    echo "🖼️ Resize (vips, $CONV_RAM RAM)"; vips thumbnail "$input" "$output" "$width"
  else
    echo "🖼️ Resize (sips, RAM-schonend)"; sips --resampleWidth "$width" "$input" --out "$output"
  fi
}
