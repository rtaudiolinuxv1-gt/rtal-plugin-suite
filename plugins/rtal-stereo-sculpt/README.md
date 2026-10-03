# rtal-stereo-sculpt

`rtal-stereo-sculpt` is a mid/side stereo imager: width, bass mono, side brightness, Haas widening for mono sources, balance and a correlation meter.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The signal is split into mid (what both speakers share) and side (the difference). Width scales the side signal, while everything below the `Bass Mono` crossover is removed from the side so the low end stays centred and mono compatible. The side can be brightened or darkened, and Haas widening injects a short delayed copy into the side, giving width even to a mono guitar. The correlation meter shows +1 for mono, 0 for wide and negative values for phase problems.

## Controls

- `Width`: 0 mono, 0.5 unchanged, 1 double width.
- `Bass Mono`: frequency below which the image is folded to mono.
- `Side Brightness`: tilt of the side signal.
- `Haas Widen`: delayed copy into the side for width from mono sources.
- `Mid Level`: +/-6 dB on the mid.
- `Balance`: left/right balance.
- `Correlation`: phase correlation meter.

## Factory presets

- `Wide Master`: gently widened with brighter sides.
- `Mono-Safe Bass`: wide top with a firmly mono low end.
- `Haas Double`: Haas widening for mono guitars.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-stereo-sculpt-lv2
cmake --build build --target rtal-stereo-sculpt-standalone
cmake --build build --target rtal-stereo-sculpt-vst2
cmake --build build --target rtal-stereo-sculpt-package
```
