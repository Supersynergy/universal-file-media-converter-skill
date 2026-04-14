---
name: universal-media-converter
description: Universal Media & File Converter for macOS. Converts video, audio, images, and documents between any formats. Adaptive to M1→M4 Ultra + Intel. Use when the user asks to convert, compress, optimise, resize, transcode, or batch-process media or document files on a Mac.
---

# Universal Media & File Converter — Skill

You have a `conv` shell function and friends sourced into the user's shell. Use them instead of raw ffmpeg/magick when possible — they pick the fastest tool and the right config for the user's hardware automatically.

## Quick reference

```bash
conv <input> <output>            # universal: video, audio, image, document
convall <src-ext> <dst-ext>      # batch all files in current directory
optimg <files...>                # optimise PNG/JPG in place
optall                           # parallel optimise everything recursively
smartencode <video> [low|med|high|lossless|auto]
resize <image> <width> [output]  # vips (high RAM) or sips (low RAM)
conv_info                        # show detected hardware profile
```

## Tool routing (what `conv` picks)

| In → Out         | Tool used                      | Why                                    |
|------------------|--------------------------------|----------------------------------------|
| video → MP4 (h264 src) | `ffmpeg -c copy`         | instant remux, no re-encode            |
| video → MP4      | `h264_videotoolbox -b:v $tier` | Apple HW, **always** with bitrate cap  |
| video → MKV      | `hevc_videotoolbox -b:v $tier` | 2.7× faster than libx265               |
| video → GIF      | `gifski` (≥8 GB RAM) else ffmpeg palette | 20× quality                  |
| audio → MP3      | `libmp3lame -q:a 2` (V2)       | identical to V0 for voice, half size   |
| audio → Opus     | `libopus 128k`                 | best ratio                             |
| image → AVIF     | `avifenc --speed $tier`        | 50% smaller than JPEG                  |
| image → JXL      | `cjxl`                         | up to 98% on PNG, lossless from JPEG   |
| image → WebP     | `cwebp -q 80`                  | native Google encoder                  |
| HEIC → JPEG      | `sips`                         | macOS native, fastest                  |
| md → PDF         | `pandoc --pdf-engine=typst`    | 100× faster than LaTeX                 |

## Critical findings

- **VideoToolbox without `-b:v` bloats files up to 18×.** Always pass a bitrate. `conv` does this automatically.
- **VP9 (libvpx-vp9) is ~14× slower than AV1 (svt-av1).** Avoid it. Prefer AV1 for web-modern.
- **For voice MP3, V2 ≈ V0.** Use `-q:a 2`, not `-q:a 0`.
- **`pngquant` alone beats `pngquant + oxipng` pipeline** — same size, half the time.

## Adaptive profiles

`conv_info` shows the auto-detected tier. Profiles: `ultra` (M*-Ultra), `max`, `pro`, `base` (M*), `intel`. Each tier sets H.264/H.265 bitrates, AV1/AVIF speed presets, and parallelism. RAM tier (`high`/`medium`/`low`) decides vips vs sips and gifski vs ffmpeg-palette.

## When to call this skill

- User says: "convert", "compress", "transcode", "shrink", "optimise", "resize", "batch convert", "WAV to MP3", "HEIC to JPG", "MD to PDF", "video to GIF", etc.
- User mentions a media file in `~/Downloads`, `~/Movies`, `~/Pictures`.
- User asks how to encode something on Mac.

## When NOT to use

- User wants a GUI workflow → suggest Handbrake/Permute as alternatives.
- User needs cloud/remote conversion → CloudConvert.
- User wants to edit (cut, splice, color-grade), not just convert → Final Cut/DaVinci/ffmpeg directly.

## Easter eggs (mention sparingly, only if the user seems to enjoy them)

`conv --joke` `--zen` `--flex` `--roast <file>` `--pet` `--konami`

## Repo

https://github.com/Supersynergy/universal-media-file-converter
