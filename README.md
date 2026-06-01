<p align="center">
  <img src="docs/assets/social-preview.png" alt="conv social preview" width="100%">
</p>

# conv

> Mac-native universal file and media converter for developers who want one command, adaptive defaults, and benchmark-backed ffmpeg flags instead of hand-tuned conversion scripts.

[![macOS](https://img.shields.io/badge/macOS-11%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M1_to_M4_Ultra-555?logo=apple&logoColor=white)](#adaptive-profiles)
[![Intel](https://img.shields.io/badge/Intel-supported-0071c5?logo=intel&logoColor=white)](#adaptive-profiles)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ShellCheck](https://github.com/Supersynergy/universal-file-media-converter-skill/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Supersynergy/universal-file-media-converter-skill/actions/workflows/shellcheck.yml)
[![Smoke](https://github.com/Supersynergy/universal-file-media-converter-skill/actions/workflows/smoke.yml/badge.svg)](https://github.com/Supersynergy/universal-file-media-converter-skill/actions/workflows/smoke.yml)

```bash
conv input.any output.any
```

`conv` routes video, audio, image, and document conversions through the fastest available local tool for your Mac. It detects Apple Silicon vs Intel, RAM tier, VideoToolbox support, and safe parallelism, then applies defaults learned from 55+ local benchmarks.

## Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Supersynergy/universal-file-media-converter-skill/main/install.sh)"
source ~/.zshrc
conv_info
```

Expected result: `conv_info` prints your detected profile and `conv --help` is available in the current shell.

Prefer to inspect first:

```bash
git clone https://github.com/Supersynergy/universal-file-media-converter-skill
cd universal-file-media-converter-skill
sed -n '1,140p' install.sh
```

Uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/Supersynergy/universal-file-media-converter-skill/main/uninstall.sh | bash
```

## Try It

```bash
conv movie.mkv movie.mp4        # remux to MP4 when copy is safe
conv photo.heic photo.jpg       # native HEIC to JPEG through sips
conv voice.wav voice.mp3        # speech-friendly MP3 defaults
conv design.png design.jxl      # JPEG XL compression
conv notes.md notes.pdf         # Markdown to PDF through pandoc/typst
```

Typical benchmark examples from the included M4 Max run:

| Task | Result |
|---|---:|
| MKV to MP4 remux | `0.18s` |
| HEIC to JPEG | `0.20s` |
| WAV voice to MP3 V2 | `0.21s`, 95% smaller |
| PNG to JXL q85 | `0.49s`, 98.4% smaller |
| Typst to PDF | `0.22s` |

See [BENCHMARKS.md](BENCHMARKS.md) for the full data and caveats.

## Why It Exists

Raw `ffmpeg` is powerful, but the defaults are easy to get wrong. On the benchmark input, this one missing bitrate flag changed the output size by an order of magnitude:

```text
ffmpeg -c:v h264_videotoolbox            1791% output ratio
ffmpeg -c:v h264_videotoolbox -b:v 6000k  744% output ratio
ffmpeg -c:v h264_videotoolbox -b:v 4000k  496% output ratio
ffmpeg -c:v h264_videotoolbox -b:v 2000k  277% output ratio
```

`conv` keeps the useful part of ffmpeg and removes the repeated decision work: format routing, hardware profile, bitrate, encoder preset, image optimizer, and batch safety.

## Tool Map

| Command | Use |
|---|---|
| `conv <input> <output>` | Convert one file with automatic routing |
| `conv_info` | Show detected CPU, RAM, VideoToolbox, and defaults |
| `convall <src> <dst>` | Batch convert files in the current directory |
| `optimg <files...>` | Optimize PNG/JPG files in place |
| `optall` | Recursively optimize images in parallel |
| `smartencode <video> [low|med|high|lossless|auto]` | Encode video with named quality targets |
| `resize <image> <width>` | Resize through `vips` or `sips` depending on profile |

Powered by `ffmpeg`, `vips`, `gifski`, `oxipng`, `pngquant`, `jpegoptim`, `cjxl`, `avifenc`, `cwebp`, `typst`, `pandoc`, `sox`, `sips`, `ImageMagick`, `ab-av1`, and `mediainfo`.

## Adaptive Profiles

`conv` initializes once per shell and exports conversion defaults for your machine.

| Profile | Hardware | H.264 | H.265 | AV1 | AVIF | Parallel | Resize |
|---|---|---:|---:|---:|---:|---:|---|
| Ultra | M-series Ultra | `6000k` | `5000k` | `p6` | `s4` | 8 | `vips` |
| Max | M-series Max | `4000k` | `3000k` | `p8` | `s6` | 6 | `vips` |
| Pro | M-series Pro | `4000k` | `3000k` | `p8` | `s6` | 4 | `vips` |
| Base | M1/M2/M3/M4 | `3000k` | `2500k` | `p10` | `s8` | 2 | `sips` |
| Intel | Intel Mac | `libx264 -crf 23` | `libx265 -crf 28` | `p12` | `s9` | 2 | `sips` |

Overrides:

```bash
CONV_H264_BR=8000k conv in.mov out.mp4
CONV_SOUND=0 conv in.wav out.mp3
CONV_KONAMI=1 conv in.mkv out.mp4
```

## Repository Layout

| Path | Purpose |
|---|---|
| [converter.sh](converter.sh) | Main shell implementation |
| [install.sh](install.sh) | Homebrew dependency install and shell wiring |
| [uninstall.sh](uninstall.sh) | Removes installed files and shell hook |
| [skill/universal-media-converter.md](skill/universal-media-converter.md) | Agent skill for Claude Code / GG Coder style workflows |
| [BENCHMARKS.md](BENCHMARKS.md) | Benchmark table and Pareto findings |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Benchmark and PR guide |

## Agent Integration

The installer copies the bundled skill into `~/.gg/skills/` when that directory exists. Agents can then call `conv` instead of inventing raw ffmpeg commands.

Skip skill installation:

```bash
CONV_SKILL_DIR=/dev/null /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Supersynergy/universal-file-media-converter-skill/main/install.sh)"
```

Agent instructions for this repository live in [AGENTS.md](AGENTS.md).

## Development

```bash
brew install shellcheck ffmpeg pandoc imagemagick webp libavif jpeg-xl
shellcheck converter.sh install.sh uninstall.sh
source ./converter.sh
conv_info
conv --help
```

The GitHub Actions suite runs ShellCheck on Ubuntu and smoke conversions on macOS.

## Limits

- macOS only.
- Benchmarks are from one M4 Max system; your files and hardware will differ.
- The CatBoost note is about ranking tested configs, not predicting universal outcomes.
- `pipe | bash` is convenient but always deserves inspection. Read [install.sh](install.sh) if you are unsure.

## Contributing

The highest-value contribution is a benchmark from a real Mac. M1 base, M2 Pro, M3 Ultra, Intel, and unusual media files are especially useful. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © Supersynergy.
