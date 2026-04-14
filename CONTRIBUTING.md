# Contributing

Thanks for considering a contribution! This project lives or dies by **real benchmarks on real Macs** — that's the most valuable thing you can give.

## 🎯 Most-wanted contributions

1. **Benchmarks on your Mac.** Run `bench/run.sh` (coming soon — for now: `conv_info` + a few `time conv …` runs) and open an issue with the output. M1 base, M2 Pro, M3 Ultra, Intel — all wanted.
2. **Bug reports.** Especially edge cases: filenames with spaces/emoji, unusual codecs, exotic formats.
3. **New format support.** If your favourite format isn't routed in `converter.sh`, add a case and PR it.
4. **Easter eggs.** Jokes, koans, ASCII art for `--pet` evolution, achievements. Keep it tasteful.
5. **Tool replacements.** If you find something faster than what we use, prove it with a benchmark.

## ✅ Before opening a PR

```bash
# Lint
brew install shellcheck
shellcheck converter.sh install.sh uninstall.sh

# Smoke test
source converter.sh
conv_info
conv --help
```

## 🧭 Style

- POSIX-ish bash. Quote your variables. Use `printf` over `echo -e`.
- Prefer `find -print0 | xargs -0` over `ls`/glob for filenames.
- No new mandatory dependencies without a benchmark justifying them.
- Keep functions small. The whole script should stay readable in one screen per function.

## 🤝 Code of Conduct

Be kind. Assume good faith. Roast files, not people. (`conv --roast` is for files only.)
