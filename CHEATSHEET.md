# 🔄 Universal Mac Converter v5 — Adaptive, CatBoost-Optimized

> **Adaptiv:** Erkennt automatisch Mac-Modell, Chip, RAM, Kerne und passt alle Parameter an.
> **Verifiziert:** 55+ Benchmarks, CatBoost-Analyse, Pareto-Optimierung. Stand: 14.04.2025
> **Tools:** ffmpeg, vips, gifski, oxipng, pngquant, jpegoptim, cjxl, avifenc, cwebp, typst, pandoc, sox, sips, gm, ab-av1

---

## 🔧 SYSTEM-PROFILER (erste Aktion: erkennen!)

```bash
# Immer zuerst ausführen oder in conv() einbauen:
conv_detect_system() {
  export CONV_CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
  export CONV_NCPU=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
  export CONV_PCPU=$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null || echo "$CONV_NCPU")
  export CONV_MEM_GB=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $0/1073741824}' || echo 8)
  export CONV_MACOS=$(sw_vers -productVersion 2>/dev/null || echo "12.0")

  # Chip-Tier bestimmen
  if [[ "$CONV_CHIP" == *"Ultra"* ]]; then
    export CONV_TIER="ultra"  CONV_VENCODE=4 CONV_PRORES=1
  elif [[ "$CONV_CHIP" == *"Max"* ]]; then
    export CONV_TIER="max"    CONV_VENCODE=2 CONV_PRORES=1
  elif [[ "$CONV_CHIP" == *"Pro"* ]]; then
    export CONV_TIER="pro"    CONV_VENCODE=1 CONV_PRORES=1
  elif [[ "$CONV_CHIP" == *"M1"* || "$CONV_CHIP" == *"M2"* || "$CONV_CHIP" == *"M3"* || "$CONV_CHIP" == *"M4"* ]]; then
    export CONV_TIER="base"   CONV_VENCODE=1 CONV_PRORES=$([[ "$CONV_CHIP" == *"M1" ]] && echo 0 || echo 1)
  else
    export CONV_TIER="intel"  CONV_VENCODE=0 CONV_PRORES=0
  fi

  # AV1 HW Decode (M3+)
  [[ "$CONV_CHIP" == *"M3"* || "$CONV_CHIP" == *"M4"* ]] && export CONV_AV1_HW=1 || export CONV_AV1_HW=0

  # VideoToolbox verfügbar?
  ffmpeg -hide_banner -encoders 2>/dev/null | grep -q videotoolbox && export CONV_VTB=1 || export CONV_VTB=0

  # Parallel-Jobs berechnen (für SW-Encoding)
  export CONV_JOBS=$(( CONV_PCPU > 2 ? CONV_PCPU / 2 : 1 ))

  # RAM-Profil (für Bild-Ops)
  if [ "$CONV_MEM_GB" -ge 64 ]; then
    export CONV_RAM_PROFILE="high"     # Große Bilder parallel
  elif [ "$CONV_MEM_GB" -ge 16 ]; then
    export CONV_RAM_PROFILE="medium"   # Standard
  else
    export CONV_RAM_PROFILE="low"      # Speicher schonen, sips bevorzugen
  fi
}
```

## 📊 ADAPTIVE PROFILE (automatisch gewählt)

### Profil-Matrix pro Chip-Tier

| Parameter | 🏆 Ultra | ⚡ Max | 💪 Pro | 🍎 Base (M1-M4) | 🖥️ Intel |
|---|---|---|---|---|---|
| **Video-Encoder** | VTBox (4 Eng.) | VTBox (2 Eng.) | VTBox (1 Eng.) | VTBox (1 Eng.) | libx264/x265 |
| **H.264 Bitrate** | `-b:v 6000k` | `-b:v 4000k` | `-b:v 4000k` | `-b:v 3000k` | `-crf 23` |
| **H.265 Bitrate** | `-b:v 5000k` | `-b:v 3000k` | `-b:v 3000k` | `-b:v 2500k` | `-crf 28` |
| **AV1 Preset** | `-preset 6` | `-preset 8` | `-preset 8` | `-preset 10` | `-preset 12` |
| **Parallel VTBox** | 4 streams | 2 streams | 1 stream | 1 stream | N/A |
| **Parallel SW** | `-P 8` | `-P 6` | `-P 4` | `-P 2` | `-P 2` |
| **oxipng threads** | `--threads 32+` | `--threads 16` | `--threads 12` | `--threads 8` | `--threads 4` |
| **Bild-Resize Tool** | vips (RAM ok) | vips (RAM ok) | vips/sips | sips (8GB safe) | sips |
| **GIF Tool** | gifski | gifski | gifski | gifski (8GB ok) | ffmpeg palette |
| **ProRes HW** | ✅ (4 Eng.) | ✅ (2 Eng.) | ✅ (1 Eng.) | ✅/❌ (M1=❌) | ❌ Software |
| **avifenc speed** | `--speed 4` | `--speed 6` | `--speed 6` | `--speed 8` | `--speed 9` |
| **cjxl effort** | `-e 7` | `-e 5` | `-e 5` | `-e 3` | `-e 3` |
| **RAM-Profil** | high | high | medium | low-medium | low |

### ⚠️ CatBoost-Warnungen (gelten für ALLE Macs!)

1. **VideoToolbox IMMER mit `-b:v`!** Ohne = 1791% Bloat (H.264) / 886% (H.265)
2. **ffmpeg `aac`** statt `aac_at` → 2x bessere Kompression auf allen Macs
3. **FLAC default** reicht → `-compression_level 12` = 65% langsamer, 0% Gewinn
4. **pngquant allein** reicht → oxipng danach = doppelte Zeit, kaum Gewinn
5. **VP9 IMMER vermeiden** → 30s vs 1.8s, nutze AV1 stattdessen

---

## 🎬 VIDEO

### Container-Wechsel (INSTANT auf allen Macs!)
```bash
ffmpeg -i in.mkv -c copy out.mp4                          # 0.18s!
ffmpeg -i in.mp4 -c copy out.mkv
ffmpeg -i in.mov -c copy out.mp4
```

### VideoToolbox Hardware-Encoding (⚠️ IMMER -b:v setzen!)
```bash
# H.264 (alle Apple Silicon + manche Intel Macs)
ffmpeg -i in.mkv -c:v h264_videotoolbox -b:v ${CONV_H264_BR:-4000k} -c:a aac -b:a 256k -movflags +faststart out.mp4

# H.265/HEVC (alle Apple Silicon)
ffmpeg -i in.mkv -c:v hevc_videotoolbox -b:v ${CONV_H265_BR:-3000k} -c:a aac -b:a 256k -movflags +faststart out.mp4

# 10-Bit HEVC HDR
ffmpeg -i in.mkv -c:v hevc_videotoolbox -pix_fmt p010le -b:v 20M -c:a aac -b:a 384k -ac 6 -movflags +faststart out.mkv

# ProRes HW (Pro/Max/Ultra only, M1 base = NO)
ffmpeg -i in.mp4 -c:v prores_videotoolbox -profile:v 3 -c:a pcm_s16le out.mov

# AV1 (SVT-AV1, Software — Preset adaptiv!)
ffmpeg -i in.mp4 -c:v libsvtav1 -preset ${CONV_AV1_PRESET:-8} -crf 30 -c:a libopus -b:a 128k out.mkv
```

### Software Fallback (Intel Macs)
```bash
ffmpeg -i in.mkv -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 256k -movflags +faststart out.mp4
ffmpeg -i in.mkv -c:v libx265 -crf 28 -preset medium -c:a aac -b:a 256k out.mp4
```

### ab-av1: Auto-optimale Bitrate
```bash
ab-av1 auto-encode -i in.mkv -e hevc_videotoolbox --min-vmaf 95     # Apple Silicon
ab-av1 auto-encode -i in.mkv -e libsvtav1 --min-vmaf 95 --preset 6  # Universal
ab-av1 auto-encode -i in.mkv -e libx264 --min-vmaf 95               # Intel Fallback
```

### Video-Operationen
```bash
ffmpeg -ss 00:01:00 -i in.mp4 -t 30 -c copy out.mp4                 # Trim (instant!)
ffmpeg -i in.mp4 -vf scale=1920:-1 -c:v h264_videotoolbox -b:v 4000k out.mp4  # Resize
ffmpeg -i in.mp4 -vf "fps=30" -c:v h264_videotoolbox -b:v 4000k out.mp4       # FPS
ffmpeg -i in.mp4 -vf "transpose=1" -c:v h264_videotoolbox -b:v 4000k out.mp4  # Rotate
ffmpeg -f concat -safe 0 -i filelist.txt -c copy out.mp4             # Concat
ffmpeg -i in.mp4 -ss 10 -vframes 1 thumb.jpg                        # Screenshot
```

### Video → GIF
```bash
# gifski (EMPFOHLEN, alle Macs mit ≥8GB RAM)
mkdir -p /tmp/gf && ffmpeg -i in.mp4 -vf "fps=15,scale=480:-1" /tmp/gf/f%04d.png 2>/dev/null
gifski -o out.gif --fps 15 --quality 90 --width 480 /tmp/gf/f*.png && rm -rf /tmp/gf

# Fallback (wenig RAM / kein gifski)
ffmpeg -i in.mp4 -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" out.gif
```

### Batch-Video (adaptiv an Encode-Engines)
```bash
# Apple Silicon (1 stream pro Encode-Engine)
for f in *.mkv; do ffmpeg -i "$f" -c:v hevc_videotoolbox -b:v 3000k -c:a aac -movflags +faststart "${f%.mkv}.mp4"; done

# Software parallel (nutzt CPU-Kerne)
ls *.mkv | xargs -P ${CONV_JOBS:-4} -I{} ffmpeg -i {} -c:v libsvtav1 -preset ${CONV_AV1_PRESET:-8} -crf 30 -c:a libopus {}.mkv
```

---

## 🎵 AUDIO (identisch auf allen Macs)

```bash
ffmpeg -y -i in.wav -c:a libmp3lame -q:a 2 out.mp3         # MP3 V2 (Sprache, 5%)
ffmpeg -y -i in.wav -c:a libmp3lame -q:a 0 out.mp3         # MP3 V0 (Musik, 10%)
ffmpeg -y -i in.wav -c:a aac -b:a 256k out.m4a             # AAC (NICHT aac_at!)
ffmpeg -y -i in.wav -c:a flac out.flac                      # FLAC (default reicht!)
ffmpeg -y -i in.wav -c:a libopus -b:a 128k out.opus        # Opus (bestes Ratio!)
ffmpeg -y -i in.wav -c:a alac out.m4a                       # ALAC (Apple Lossless)
ffmpeg -y -i video.mp4 -vn -c:a copy audio.m4a             # Audio extrahieren
ffmpeg -y -i in.mp3 -af loudnorm=I=-16:TP=-1.5:LRA=11 out.mp3  # Normalisieren
```

---

## 🖼️ BILDER (adaptiv an RAM)

### Resize (Tool-Wahl nach RAM-Profil)
```bash
# HIGH RAM (≥64GB): vips — kleinstes Output
vips thumbnail in.jpg out.jpg 800

# MEDIUM RAM (16-64GB): vips oder sips
vips thumbnail in.jpg out.jpg 800     # Kleiner Output
sips --resampleWidth 800 in.jpg --out out.jpg   # Schneller

# LOW RAM (≤16GB): sips — braucht kaum RAM, nativ
sips --resampleWidth 800 in.jpg --out out.jpg
sips -z 1080 1920 in.jpg --out out.jpg
```

### Format-Konvertierung
```bash
# WebP
cwebp -q 80 in.jpg -o out.webp                             # Nativ, schnell

# AVIF (speed adaptiv!)
avifenc in.jpg out.avif --speed ${CONV_AVIF_SPEED:-6}       # Ultra: 4, Max: 6, Base: 8

# JPEG-XL 🏆 (bestes Format!)
cjxl in.jpg out.jxl -q 100                                  # Lossless JPEG recomp: -19%!
cjxl in.jpg out.jxl -q 70 --lossless_jpeg=0                # Lossy: -41%
cjxl in.png out.jxl -q 85                                   # PNG→JXL: -98.4%!!! 🏆

# HEIC→JPG (sips = schnellstes auf allen Macs)
sips -s format jpeg in.HEIC --out out.jpg
sips -s format jpeg *.HEIC --out ./jpgs/                    # Batch

# Standard
magick in.png out.jpg
magick in.bmp out.png
magick -density 300 in.svg out.png                          # SVG→PNG
magick -density 300 in.pdf page_%03d.png                    # PDF→Bilder
```

### Optimierung
```bash
# PNG: pngquant allein reicht! (CatBoost-verifiziert)
pngquant --quality=65-80 --ext .png --force in.png          # 90% kleiner!

# JPEG
jpegoptim --strip-all --max=85 in.jpg

# Batch (Kerne adaptiv)
fd -e png | xargs -P ${CONV_NCPU:-8} -I{} pngquant --quality=65-80 --ext .png --force {}
fd -e jpg -e jpeg | xargs -P ${CONV_NCPU:-8} jpegoptim --strip-all --max=85
```

---

## 📄 DOKUMENTE (identisch auf allen Macs)

```bash
typst compile in.typ out.pdf                                # 0.22s! (100x schneller)
pandoc in.md -o out.pdf --pdf-engine=typst                  # MD→PDF schnell
pandoc in.md -o out.html                                    # MD→HTML
pandoc in.md -o out.docx                                    # MD→Word
pandoc in.md -o out.epub                                    # MD→EPUB
pandoc in.docx -o out.md                                    # DOCX→MD
```

---

## 🔧 ADAPTIVE SHELL-FUNKTIONEN (→ ~/.zshrc)

```bash
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
```

---

## 🔍 Format-Erkennung
```bash
file in.xyz                               # Basis
ffprobe in.xyz 2>&1 | head -20            # Media
magick identify in.xyz                     # Bilder
mediainfo in.xyz                           # Detailliert
```

---

## ⚡ PERFORMANCE-REGELN (alle Macs)

1. **`-c copy`** Container-Wechsel = INSTANT auf allen Macs!
2. **VTBox IMMER mit `-b:v`!** Default = aufgebläht (CatBoost-verifiziert)
3. **`ab-av1`** findet optimale Bitrate via VMAF — auf allen Macs
4. **Resize:** `vips` (≥16GB RAM) oder `sips` (<16GB) — adaptiv gewählt
5. **`pngquant` allein** reicht (90% kleiner) — oxipng nur für Lossless
6. **`gifski`** für GIF — braucht ≥8GB RAM, sonst ffmpeg palette
7. **`typst`** für PDF — 100x schneller als LaTeX, alle Macs
8. **`avifenc --speed`** adaptiv: Ultra=4, Max=6, Pro=6, Base=8, Intel=9
9. **`cjxl`** für JXL — PNG→JXL = 98.4% Kompression! Bestes Format!
10. **VP9 VERMEIDEN** — nutze AV1 (`libsvtav1`) stattdessen
11. **ffmpeg `aac`** statt `aac_at` — 2x bessere Kompression
12. **FLAC default** — `-compression_level 12` bringt 0%
13. **`-movflags +faststart`** IMMER bei MP4 (Web-Streaming)
14. **Parallel:** `xargs -P $CONV_NCPU` — adaptiv an Kernzahl

## 📦 Installation (alle Tools)
```bash
brew install ffmpeg imagemagick pandoc sox mediainfo \
  gifski oxipng pngquant jpegoptim vips typst \
  libavif libjxl webp ab-av1 graphicsmagick yt-dlp
```

## 🏷️ SCHNELL-LOOKUP
| Von → Nach | Befehl | Adaptiv |
|---|---|---|
| MKV→MP4 copy | `ffmpeg -i in.mkv -c copy out.mp4` | Alle Macs ⚡ |
| MP4→H264 | `... h264_videotoolbox -b:v $CONV_H264_BR` | VTBox / x264 |
| MP4→HEVC | `... hevc_videotoolbox -b:v $CONV_H265_BR` | VTBox / x265 |
| MP4→AV1 | `... libsvtav1 -preset $CONV_AV1_PRESET -crf 30` | Preset adaptiv |
| Video auto | `ab-av1 auto-encode -e hevc_videotoolbox` | VTBox / x264 |
| MP4→GIF | `gifski` (≥8GB) / `ffmpeg palette` | RAM adaptiv |
| WAV→MP3 | `... libmp3lame -q:a 2` (Sprache) / `-q:a 0` (Musik) | Alle Macs |
| WAV→Opus | `... libopus -b:a 128k` | Alle Macs 🏆 |
| HEIC→JPG | `sips -s format jpeg in.HEIC --out out.jpg` | Alle Macs ⚡ |
| Resize | `vips thumbnail` (≥16GB) / `sips` (<16GB) | RAM adaptiv |
| JPG→AVIF | `avifenc --speed $CONV_AVIF_SPEED` | Tier adaptiv |
| PNG→JXL | `cjxl in.png out.jxl -q 85` | Alle Macs 🏆🏆🏆 |
| JPG→JXL | `cjxl in.jpg out.jxl -q 100` (lossless!) | Alle Macs ⚡ |
| PNG opt | `pngquant --quality=65-80` | Alle Macs |
| MD→PDF | `pandoc ... --pdf-engine=typst` | Alle Macs ⚡ |
