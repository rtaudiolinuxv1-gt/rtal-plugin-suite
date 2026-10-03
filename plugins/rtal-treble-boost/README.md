# rtal-treble-boost

`rtal-treble-boost` is a germanium-style range booster: a single-transistor treble, mid or full-range boost with gentle, lopsided grit.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The input capacitor of a classic range booster decides what gets boosted: a small one for treble, a larger one for mids, a large one for the full range. Here a high shelf at the matching corner provides up to 22 dB of boost, followed by a lightly biased germanium-style stage whose asymmetric soft clipping adds grit as you hit it harder.

## Controls

- `Range`: Treble, Mid or Full boost.
- `Boost`: amount of boost, up to 22 dB.
- `Bias`: transistor bias; higher is more lopsided.
- `Grit`: drive into the transistor stage.
- `Level`: output level.

## Factory presets

- `British Treble`: classic treble booster into a cranked amp.
- `Mid Lead Kick`: mid-focused lead boost.
- `Clean Full Lift`: clean full-range level boost.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-treble-boost-lv2
cmake --build build --target rtal-treble-boost-standalone
cmake --build build --target rtal-treble-boost-vst2
cmake --build build --target rtal-treble-boost-package
```
