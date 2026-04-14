<div align="center">

```
                                                  ┌──────────┐
                                                  │  $ conv  │
                                                  └──────────┘

      ▄████▄   ▒█████   ███▄    █  ██▒   █▓
     ▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █ ▓██░   █▒
     ▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒ ▓██  █▒░
     ▒▓▓▄ ▄██▒▒██   ██░▓██▒  ▐▌██▒  ▒██ █░░
     ▒ ▓███▀ ░░ ████▓▒░▒██░   ▓██░   ▒▀█░
     ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒    ░ ▐░
       ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░   ░ ░░
     ░        ░ ░ ░ ▒     ░   ░ ░      ░░
     ░ ░          ░ ░           ░       ░
     ░                                 ░

   universal media & file converter — for macOS
```

# `conv`

### **Convert anything on your Mac. The fastest way possible.**

**One command.** Sixteen tools underneath. Zero config. Built on **55+ real benchmarks**
across video, audio, images, and documents — and a hardware profile that adapts itself
to your chip the moment you source it.

```bash
conv anything.in anything.out      # that's the entire API
```

[![macOS](https://img.shields.io/badge/macOS-11%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M1→M4_Ultra-555?logo=apple&logoColor=white)](#-adaptive-profiles)
[![Intel](https://img.shields.io/badge/Intel-supported-0071c5?logo=intel&logoColor=white)](#-adaptive-profiles)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ShellCheck](https://github.com/Supersynergy/universal-file-media-converter-skill/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Supersynergy/universal-file-media-converter-skill/actions/workflows/shellcheck.yml)
[![Smoke](https://github.com/Supersynergy/universal-file-media-converter-skill/actions/workflows/smoke.yml/badge.svg)](https://github.com/Supersynergy/universal-file-media-converter-skill/actions/workflows/smoke.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## ⚡ 30 seconds

```bash
$ conv movie.mkv movie.mp4
🎬 → MP4 (copy, INSTANT!)         0.24s

$ conv photo.heic photo.jpg
🖼  → JPEG (sips, native HEIC)    0.20s

$ conv voice.wav voice.mp3
🎵 → MP3                          0.29s   (90% smaller)

$ conv design.png design.jxl
🖼  → JXL                         0.49s   (98% smaller 🤯)
```

That's it. `conv` figures out the right tool, the right config, and the right hardware path for **your** Mac.

---

## 📦 Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Supersynergy/universal-file-media-converter-skill/main/install.sh)"
```

Want to read it first? **[install.sh](install.sh)** is 60 lines. We respect that.

**Uninstall any time** — `curl -fsSL https://raw.githubusercontent.com/Supersynergy/universal-file-media-converter-skill/main/uninstall.sh | bash`

---

## 🤔 Why not just use…?

| Tool             | What it's good at                | What it lacks                                   |
|------------------|----------------------------------|-------------------------------------------------|
| **Handbrake**    | GUI, presets, queue              | Slow, bloated, GUI-only, video only             |
| **Permute** ($)  | Drag-drop, polish                | $15, closed source, slow on big batches         |
| **CloudConvert** | Anything → anything in browser   | Uploads your files, $$$, slow                   |
| **ffmpeg** (raw) | Everything                       | Manual flags, easy to misconfigure (see below)  |
| **`conv`**       | Picks the fastest tool + correct config for your hardware automatically | Mac-only, CLI-only |

**The one chart that explains why this exists:**

```
The VideoToolbox Trap — same input, same encoder, different flags
─────────────────────────────────────────────────────────────────
ffmpeg -c:v h264_videotoolbox            ████████████████████████████  1791% bloat
ffmpeg -c:v h264_videotoolbox -b:v 6000k █████████                      743%
ffmpeg -c:v h264_videotoolbox -b:v 4000k █████                          496%   ← conv default (max)
ffmpeg -c:v h264_videotoolbox -b:v 2000k ███                            277%   ← conv default (base)
```

A single missing flag is the difference between **18× bloat** and **3×**. `conv` always passes the right flag.

---

## 🧪 The benchmarks (real files, real Macs)

Run on **MacBook Pro M4 Max · 16 cores · 128 GB · ffmpeg 8.1**. [Full numbers in BENCHMARKS.md](BENCHMARKS.md). [Re-run on your Mac and PR them.](CONTRIBUTING.md)

### 🎬 Video — H.265 encode

```
hevc_videotoolbox -b:v 3000k  ███             1.79s    ← conv default
libx265 -crf 28               ████████████    4.90s     2.7× slower
libvpx-vp9 (VP9, WebM)        █████████████████████████████  30.2s   17× slower 🐌
```

### 🖼 Image — 4 K → 800 px resize

```
sips                          █     0.20s    ← chosen on low-RAM Macs
vips thumbnail                █     0.24s    ← chosen on high-RAM Macs
ffmpeg                        █     0.18s
ImageMagick                   ███   0.62s     ~3× slower
```

### 🎵 Audio — voice WAV → compressed

```
                              size       ratio
MP3 V2 (libmp3lame -q:a 2)    136 KB     5.3%   ← conv default for voice
MP3 V0                        268 KB    10.4%
AAC ffmpeg                    479 KB    18.5%
AAC AudioToolbox              946 KB    36.6%   ← *avoid for voice*
FLAC                          360 KB    13.9%
Opus 64k                      299 KB    11.6%
```

### 🪄 The JXL revelation

```
$ ls -lh design.png design.jxl
18M   design.png
281K  design.jxl     ← cjxl q85, 98.4% smaller, perceptually identical
```

---

## 🧠 Adaptive profiles

`conv` detects your chip on first use and picks safe defaults. Run `conv_info` to see yours.

| Profile  | Hardware                   | H.264   | H.265   | AV1   | AVIF   | Parallel | Resize  |
|----------|----------------------------|---------|---------|-------|--------|----------|---------|
| 🏆 Ultra | M*-Ultra                   | 6000k   | 5000k   | p6    | s4     | 8        | vips    |
| ⚡ Max   | M*-Max                     | 4000k   | 3000k   | p8    | s6     | 6        | vips    |
| 💪 Pro   | M*-Pro                     | 4000k   | 3000k   | p8    | s6     | 4        | vips    |
| 🍎 Base  | M1/M2/M3/M4 (no Pro/Max)   | 3000k   | 2500k   | p10   | s8     | 2        | sips    |
| 🖥 Intel  | Intel Mac (no VideoToolbox)| crf 23  | crf 28  | p12   | s9     | 2        | sips    |

Override anything: `CONV_KONAMI=1 conv …` forces Ultra. `CONV_SOUND=0` silences the completion chime. `CONV_H264_BR=8000k conv …` uses your own bitrate.

---

## 🛠 What you get

```bash
conv <input> <output>          # universal converter (auto picks tool)
conv_info                      # show detected hardware profile
convall <src> <dst>            # batch in cwd, NUL-safe
optimg <files…>                # in-place PNG/JPG optimisation
optall                         # parallel recursive optimise
smartencode <video> [low|med|high|lossless|auto]
resize <image> <width>         # vips or sips, RAM-adaptive
```

Powered by: **ffmpeg · vips · gifski · oxipng · pngquant · jpegoptim · cjxl · avifenc · cwebp · typst · pandoc · sox · sips · ImageMagick · ab-av1 · mediainfo**

---

## 🥚 Easter eggs

```bash
conv --joke                # random encoding joke
conv --zen                 # encoding koan
conv --flex                # lifetime bytes-saved stats
conv --roast bigfile.png   # roasts your unoptimised file
conv --pet                 # meet Convy the Otter (he ages with usage)
conv --konami              # 🎮 force Ultra profile on any Mac
```

There's a daily fortune-cookie tip too. And a quiet completion chime — turn it off with `CONV_SOUND=0` if you're in a meeting.

---

## 🤖 AI agent integration (optional)

This repo ships a [Claude Code skill](skill/universal-media-converter.md) at `skill/universal-media-converter.md`. The installer drops it into `~/.gg/skills/` automatically if that directory exists. AI agents (Claude Code, GG Coder, etc.) will then route conversion requests through `conv` instead of writing raw ffmpeg flags.

Don't want it? Skip:

```bash
CONV_SKILL_DIR=/dev/null /bin/bash -c "$(curl -fsSL …/install.sh)"
```

---

## ⚠️ Honest limits

- **macOS only.** Linux/Windows: PRs welcome but unlikely to land.
- **The "ML-tuned" defaults** were learned by brute-forcing 55+ configs and picking Pareto-optimal ones. We use the word "CatBoost" honestly: a regression on (tool, config, file) → (time, size). R² ≈ 0.23 — useful for ranking, not for prediction. The real value is the **manually-validated Pareto front**, not the model.
- **Benchmarks are from one Mac (M4 Max).** Your numbers will differ. [Send yours.](CONTRIBUTING.md)
- **`pipe | bash` install** always carries risk. Read [install.sh](install.sh) first; it's 60 lines.

---

## 🤝 Contributing

The most-wanted PR is **a benchmark from your Mac**. M1 base, M2 Pro, M3 Ultra, Intel — all wanted. See [CONTRIBUTING.md](CONTRIBUTING.md).

## 📜 License

MIT — do anything you want. Built with love by [Supersynergy](https://github.com/Supersynergy).

---

<div align="center">

*If this saved you time, star it ⭐ and tell a friend who still uses Handbrake.*

</div>
