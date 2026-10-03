# rtal-pick-tamer

`rtal-pick-tamer` is a two-band dynamic EQ: it cuts harsh pick click and boomy low notes only when they jump out, leaving the rest alone.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Each band has its own detector listening only to its frequency range. When a pick attack spikes the presence band, or a low note blooms the boom band, a peaking EQ cuts that band by an amount that tracks how far it exceeds the threshold, up to the maximum cut, and then lets go. Unlike static EQ the guitar keeps its sparkle and body between those moments. Meters show the cut in each band.

## Controls

- `Pick Freq`: centre of the pick/presence band, 1.5 kHz to 8 kHz.
- `Pick Threshold`: level above which the pick band is cut.
- `Pick Max Cut`: maximum pick-band cut.
- `Boom Freq`: centre of the boom band, 70 Hz to 400 Hz.
- `Boom Threshold`: level above which the boom band is cut.
- `Boom Max Cut`: maximum boom-band cut.
- `Speed`: detector speed.
- `Pick Cut / Boom Cut`: meters in dB.

## Factory presets

- `Acoustic Piezo`: tames piezo quack and boom.
- `Bright Strat`: softens ice-pick highs on bright single coils.
- `Boomy Hollowbody`: controls low-end bloom on hollow bodies.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-pick-tamer-lv2
cmake --build build --target rtal-pick-tamer-standalone
cmake --build build --target rtal-pick-tamer-vst2
cmake --build build --target rtal-pick-tamer-package
```
