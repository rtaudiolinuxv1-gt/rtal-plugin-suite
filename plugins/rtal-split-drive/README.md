# rtal-split-drive

`rtal-split-drive` is a three-band multiband distortion: tight lows, crunchy mids and fizzy highs, each driven separately.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Linkwitz-Riley crossovers split the guitar into low, mid and high bands that sum back flat. Each band has its own anti-aliased (ADAA) tanh clipper with level compensation, plus its own level control. You can keep the low end clean and tight under a saturated mid range, or put fuzz only on the top.

## Controls

- `Low Drive`: drive for the low band.
- `Mid Drive`: drive for the mid band.
- `High Drive`: drive for the high band.
- `Low Split`: low/mid crossover, 80 Hz to 400 Hz.
- `High Split`: mid/high crossover, 900 Hz to 4.5 kHz.
- `Low Level`: low band output.
- `Mid Level`: mid band output.
- `High Level`: high band output.
- `Mix`: dry/wet blend.

## Factory presets

- `Tight Metal`: tight lows with heavily driven mids.
- `Bass-Safe Crunch`: clean low end under a crunchy mid range.
- `Fuzz Top Clean Bottom`: fuzz only on the highs.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-split-drive-lv2
cmake --build build --target rtal-split-drive-standalone
cmake --build build --target rtal-split-drive-vst2
cmake --build build --target rtal-split-drive-package
```
