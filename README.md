# 🔄 Universal Mac Converter

> **The fastest, smartest file converter for macOS.** Adaptive to your Mac — from M1 to M4 Ultra to Intel. CatBoost-optimized, benchmarked with 55+ real-world tests.

[![macOS](https://img.shields.io/badge/macOS-Sequoia%20|%20Sonoma%20|%20Ventura-blue)](https://apple.com/macos)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%20→%20M4%20Ultra-black)](https://apple.com)
[![Intel](https://img.shields.io/badge/Intel-Compatible-lightgrey)](https://apple.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

<p align="center">
  <img src="https://img.shields.io/badge/Video-H.264%20|%20H.265%20|%20AV1%20|%20ProRes-red" />
  <img src="https://img.shields.io/badge/Audio-MP3%20|%20FLAC%20|%20Opus%20|%20AAC-orange" />
  <img src="https://img.shields.io/badge/Image-WebP%20|%20AVIF%20|%20JXL%20|%20HEIC-purple" />
  <img src="https://img.shields.io/badge/Docs-PDF%20|%20DOCX%20|%20EPUB%20|%20HTML-blue" />
</p>

## ⚡ One-Line Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Supersynergy/universal-mac-converter/main/install.sh)"
```

Or manually:

```bash
git clone https://github.com/Supersynergy/universal-mac-converter.git
cd universal-mac-converter
./install.sh
```

## 🎯 What It Does

**Type `conv input.xyz output.abc` — it figures out the rest.**

```bash
conv video.mkv video.mp4        # → VideoToolbox H.264 (hardware-accelerated)
conv photo.heic photo.jpg       # → sips (native macOS, instant)
conv song.wav song.mp3          # → LAME V2 (optimal for speech)
conv song.wav song.opus         # → Opus (best quality/size ratio)
conv document.md document.pdf   # → typst (100x faster than LaTeX)
conv image.png image.jxl        # → JPEG-XL (98.4% compression!)
conv video.mp4 video.gif        # → gifski (20x better than ffmpeg)
```

### Adaptive to Your Mac

The converter **auto-detects your hardware** and adjusts all parameters:

| Your Mac | What Happens |
|---|---|
| **M4 Ultra** (128GB) | VideoToolbox 4 engines, `vips` for images, parallel everything |
| **M3 Max** (64GB) | VideoToolbox 2 engines, `vips` + `sips`, AV1 HW decode |
| **M2 Pro** (16GB) | VideoToolbox 1 engine, balanced parameters |
| **M1** (8GB) | VideoToolbox, `sips` for images (RAM-safe), conservative |
| **Intel Mac** | Software encoding (x264/x265), all image/audio tools work |

## 📊 Benchmarks (M4 Max, Real-World Data)

### Video Encoding
| Encoder | Time | vs Software |
|---|---|---|
| `-c copy` (remux) | **0.18s** ⚡ | ∞ |
| H.264 VideoToolbox | **1.65s** | 1.4x faster |
| H.265 VideoToolbox | **1.79s** | **2.7x faster** |
| SVT-AV1 preset 10 | **1.19s** | Best quality/size |
| VP9 (libvpx) | 30.2s 🐌 | **Avoid!** |

### Image Compression
| Format | Size vs JPEG | Speed |
|---|---|---|
| **JPEG-XL** (cjxl) | **-98.4%** from PNG 🏆 | 0.49s |
| **AVIF** (avifenc) | -50% | 0.25s |
| **WebP** (cwebp) | -43% | 0.64s |
| **pngquant** | -90% PNG | 0.84s |

### Image Resize (4K→800px)
| Tool | Time | Output Size |
|---|---|---|
| **sips** | **0.20s** ⚡ | 76K |
| **vips** | 0.24s | **38K** (smallest) |
| magick | 0.40s | 35K |

### CatBoost Key Finding

> **Config matters more than tool choice** (35.4% vs 18.7% feature importance). Always set explicit quality/bitrate — never use defaults.

⚠️ **Critical:** VideoToolbox without `-b:v` produces 1791% bloated H.264 files!

## 🛠️ All Commands

### Core Functions

| Function | Description |
|---|---|
| `conv input output` | Universal converter — auto-detects format + fastest tool |
| `convall mkv mp4` | Batch convert all files of one type |
| `conv_info` | Show detected Mac profile |
| `resize img.jpg 800` | RAM-adaptive resize (vips or sips) |
| `optimg *.png` | Optimize images (pngquant/jpegoptim) |
| `optall` | Optimize ALL images in directory (parallel) |
| `smartencode v.mp4 auto` | Smart video encode (low/med/high/lossless/auto) |

### Video
```bash
conv input.mkv output.mp4       # Auto: copy if possible, else VTBox H.264
conv input.mp4 output.mkv       # VTBox HEVC
conv input.mp4 output.gif       # gifski (high quality)
conv input.mp4 output.mov       # ProRes (if supported)
smartencode input.mp4 auto      # ab-av1 finds optimal bitrate via VMAF
smartencode input.mp4 low       # Web-optimized (1.5Mbps)
smartencode input.mp4 high      # High quality (8Mbps)
```

### Audio
```bash
conv input.wav output.mp3       # LAME V2 (optimal speech)
conv input.wav output.opus      # Best quality/size ratio
conv input.wav output.flac      # Lossless
conv input.flac output.m4a      # AAC
conv video.mp4 audio.mp3        # Extract audio
```

### Images
```bash
conv input.png output.webp      # cwebp (native Google encoder)
conv input.png output.avif      # avifenc (50% smaller than JPEG)
conv input.png output.jxl       # JPEG-XL (98.4% compression!)
conv input.heic output.jpg      # sips (native, instant)
resize input.jpg 800            # Adaptive: vips (≥16GB) or sips (<16GB)
optimg *.png *.jpg              # Optimize all
```

### Documents
```bash
conv input.md output.pdf        # pandoc + typst (fast!)
conv input.md output.docx       # pandoc
conv input.md output.html       # pandoc
conv input.typ output.pdf       # typst direct (0.22s!)
conv input.docx output.md       # pandoc
```

## 📦 What Gets Installed

| Tool | Version | Purpose | Speed Gain |
|---|---|---|---|
| ffmpeg | 8.1 | Video/Audio (VideoToolbox) | 4-8x HW accel |
| vips | 8.18 | Image resize/convert | 8x vs ImageMagick |
| gifski | 1.34 | GIF creation | 20x quality↑ |
| cjxl/djxl | 0.11 | JPEG-XL encode/decode | 98% compression |
| avifenc | 1.4 | AVIF encoding | 50% vs JPEG |
| cwebp | libwebp | WebP encoding | Native Google |
| oxipng | 10.1 | PNG lossless optimize | Multi-threaded |
| pngquant | 3.0 | PNG lossy compress | 90% smaller |
| jpegoptim | 1.5 | JPEG optimize | MozJPEG backend |
| ab-av1 | 0.11 | Auto bitrate finder | VMAF-optimal |
| typst | 0.14 | PDF generation | 100x vs LaTeX |
| pandoc | 3.9 | Document conversion | 40+ formats |
| sox | 14.4 | Audio effects | Specialized |
| ImageMagick | 7.1 | Complex image ops | Universal |
| GraphicsMagick | 1.3 | Fast image ops | Lighter |

## 🏗️ Architecture

```
conv input.ext output.ext
  │
  ├─ _conv_init()          ← Auto-detect Mac (runs once)
  │   ├─ Chip detection    ← M1/M2/M3/M4, Pro/Max/Ultra, Intel
  │   ├─ Core count        ← Performance + Efficiency
  │   ├─ RAM profiling     ← high/medium/low
  │   └─ VTBox check       ← Hardware encoder available?
  │
  ├─ Format detection      ← Input/Output extension mapping
  │
  └─ Adaptive routing
      ├─ VIDEO: VTBox (Apple Silicon) or x264/x265 (Intel)
      │   └─ Copy if codec matches container
      ├─ AUDIO: ffmpeg (all Macs)
      ├─ IMAGE: cwebp/avifenc/cjxl/sips/vips/magick
      │   └─ Resize: vips (≥16GB) or sips (<16GB)
      └─ DOCS: typst (PDF) or pandoc (everything)
```

## 🤝 Contributing

PRs welcome! Especially:
- Benchmarks on other Mac models (M1, M2 Pro, Intel i9, etc.)
- New format support
- Performance optimizations

## 📄 License

MIT — Use it, fork it, sell it. Just don't blame us if your 4K wedding video becomes a GIF.

---

<p align="center">
  Built with ❤️ by <a href="https://github.com/Supersynergy">Supersynergy</a><br>
  <sub>Powered by CatBoost analysis, 55+ benchmarks, and way too much time encoding Big Buck Bunny.</sub>
</p>
