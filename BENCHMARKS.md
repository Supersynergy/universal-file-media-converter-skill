# 📊 Benchmark Results

> All benchmarks run on Apple M4 Max · 16 cores · 128GB RAM · macOS 15.5 Sequoia
> Test date: April 14, 2025 · 55+ individual tests with real media files

## 🎬 Video Encoding

| # | Encoder | Config | Time | Output Ratio | Notes |
|---|---------|--------|------|-------------|-------|
| 1 | ffmpeg `-c copy` | remux | **0.18s** | 100% | Instant container change |
| 2 | h264_videotoolbox | `-b:v 2000k` | 1.65s | 277% | ⭐ Best H.264 config |
| 3 | h264_videotoolbox | `-q:v 40` | 1.63s | 874% | Quality mode |
| 4 | h264_videotoolbox | default (no -b:v!) | 1.69s | **1791%** ⚠️ | BLOATED! |
| 5 | h264_videotoolbox | `-b:v 6000k` | 1.64s | 744% | High bitrate |
| 6 | libx264 | `-crf 23` | 2.18s | 409% | Software reference |
| 7 | libx264 | `-crf 18` | 2.60s | 830% | High quality SW |
| 8 | hevc_videotoolbox | `-b:v 3000k` | 1.79s | 382% | ⭐ Best HEVC config |
| 9 | hevc_videotoolbox | `-q:v 40` | 1.78s | 793% | Quality mode |
| 10 | hevc_videotoolbox | default | 1.80s | **886%** ⚠️ | BLOATED! |
| 11 | libx265 | `-crf 28` | 4.23s | 183% | Software (slow!) |
| 12 | libx265 | `-crf 22` | 4.70s | 411% | High quality SW |
| 13 | libsvtav1 | `-preset 10 -crf 35` | **1.19s** | 409% | ⭐ Fastest AV1 |
| 14 | libsvtav1 | `-preset 8 -crf 30` | 2.18s | 611% | Balanced AV1 |
| 15 | libsvtav1 | `-preset 6 -crf 30` | 4.42s | 624% | Quality AV1 |
| 16 | libsvtav1 | `-preset 4 -crf 30` | 7.22s | 596% | Slow AV1 |
| 17 | prores_videotoolbox | profile 3 | 0.98s | 52980% | Lossless editing |
| 18 | libvpx-vp9 | `-b:v 2M` | **30.2s** 🐌 | 325% | AVOID! Use AV1 |

### Key Findings
- **VTBox H.265 is 2.7x faster** than software x265
- **Always set `-b:v`** with VideoToolbox — default is catastrophically bloated
- **SVT-AV1 preset 10** is actually faster than VideoToolbox with decent quality
- **VP9 is 17x slower** than VideoToolbox H.265 — always use AV1 instead

## 🎵 Audio

| Encoder | Config | Time | Compression | Notes |
|---------|--------|------|------------|-------|
| libmp3lame | `-q:a 2` (V2) | **0.21s** | 95% smaller | ⭐ Best for speech |
| libmp3lame | `-q:a 0` (V0) | 0.23s | 90% smaller | Music quality |
| libmp3lame | `-b:a 320k` | 0.26s | 55% smaller | Overkill |
| aac (ffmpeg) | `-b:a 256k` | 0.82s | 81% smaller | ⭐ Better than aac_at! |
| aac_at (Apple) | `-b:a 256k` | 0.36s | 63% smaller | 2x larger than ffmpeg! |
| libopus | `-b:a 64k` | 0.23s | 88% smaller | Good for speech |
| libopus | `-b:a 128k` | 0.23s | 79% smaller | ⭐ Best overall ratio |
| flac | default | **0.19s** | 86% smaller | ⭐ Lossless |
| flac | `-compression_level 12` | 0.31s | 86% smaller | 65% slower, 0% gain! |
| alac | default | **0.19s** | 80% smaller | Apple Lossless |

### Key Findings
- **ffmpeg `aac` produces 2x smaller** files than Apple `aac_at`
- **FLAC `best` compression is useless** — 65% slower for identical output
- **Opus 128k** is the best quality/size ratio for lossy audio
- **LAME V2** is perfect for speech (2x smaller than V0, imperceptible difference)

## 🖼️ Image Formats

| Conversion | Tool | Time | Output | Notes |
|-----------|------|------|--------|-------|
| PNG→JXL q85 | cjxl | 0.49s | **1.6%** 🏆 | Best compression ever! |
| PNG→JXL lossless | cjxl | 4.81s | 82.5% | Lossless |
| JPG→JXL lossless | cjxl | **0.25s** | 81.4% | Lossless JPEG recompression |
| JPG→JXL q70 | cjxl | 0.80s | 59.4% | Lossy |
| JPG→AVIF s8 | avifenc | **0.25s** | 56.8% | ⭐ Fast + small |
| JPG→AVIF s6 q40 | avifenc | 0.31s | **33.2%** | Maximum compression |
| JPG→AVIF s4 | avifenc | 0.94s | 54.6% | Slow, little gain |
| JPG→WebP q80 | cwebp | 0.64s | 56.8% | Good compatibility |
| JPG→WebP q90 | cwebp | 0.70s | 105.9% | Larger than JPEG! |
| JPG→WebP q80 | magick | 0.70s | 56.9% | Same as cwebp |

## 🖼️ Image Resize (4K → 800px)

| Tool | Time | Output Size | Notes |
|------|------|------------|-------|
| sips | **0.20s** ⚡ | 76K | Fastest (native macOS) |
| vips | 0.24s | **38K** | Smallest output |
| ffmpeg | 0.18s | 4.0% | Fast, good quality |
| GraphicsMagick | 0.27s | 4.1% | Middle ground |
| ImageMagick | 0.40s | 4.1% | Slowest |

## 🖼️ Image Optimization

| Tool | Time | Result | Notes |
|------|------|--------|-------|
| pngquant | **0.84s** | 18M→1.7M (**90%↓**) 🏆 | Lossy, imperceptible |
| oxipng -o2 | 1.05s | 18M→17.5M (0.5%↓) | Fast lossless |
| oxipng -o4 | 3.26s | 18M→17.4M (0.8%↓) | Balanced lossless |
| oxipng -o6 | 10.1s | 18M→17.3M (0.9%↓) | Slow, minimal gain |
| pngquant + oxipng | 1.80s | 18M→1.6M (91%↓) | Marginal gain over pngquant alone |
| jpegoptim | **0.38s** | Strips metadata | Lossless optimize |

## 📄 Documents

| Conversion | Tool | Time | Notes |
|-----------|------|------|-------|
| TYP→PDF | typst | **0.22s** ⚡ | 100x faster than LaTeX! |
| MD→PDF | pandoc+typst | 0.44s | Fast PDF engine |
| MD→HTML | pandoc | 0.27s | |
| MD→DOCX | pandoc | **0.18s** | |
| MD→EPUB | pandoc | 0.19s | |

## 🤖 CatBoost Analysis

- **R² = 0.233** on 55 datapoints
- **Feature Importance:** Category (45%) > Config (35.4%) > Tool (18.7%) > Input size (0.9%)
- **Key Insight:** Explicit config parameters matter more than tool choice

### Pareto-Optimal Configurations (non-dominated in speed AND compression)

| Category | Configuration | Speed | Compression |
|----------|--------------|-------|-------------|
| Video | copy remux | 0.18s | 100% |
| Audio | flac default | 0.19s | 13.9% |
| Audio | lame V2 | 0.21s | 5.3% |
| Image | avifenc speed 8 | 0.25s | 56.8% |
| Image | avifenc s6 q40 | 0.31s | 33.2% |
| Image | cjxl png q85 | 0.49s | 1.6% |
| Resize | vips 400px | 0.26s | 2.1% |
| Optimize | pngquant q65-80 | 0.79s | 9.9% |
