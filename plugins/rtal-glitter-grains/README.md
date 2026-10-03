# rtal-glitter-grains

`rtal-glitter-grains` is an eight-voice granular cloud delay that scatters your playing into pitched, panned and optionally reversed grains.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The input is written to a delay buffer that up to eight grain voices read from. Each grain picks a new random position, pitch from the selected set, pan and direction at the start of every window, then plays through a Hann envelope. The cloud can be fed back into the buffer for evolving textures.

## Controls

- `Pitch Set`: Unison, Octave Up, Octave Down, Octaves (random -12/0/+12), Fifths (0/+7/+12) or Shimmer (+12/+19/+24).
- `Size`: grain length, 25 ms to 400 ms.
- `Density`: number of overlapping grain voices, 1 to 8.
- `Spray`: how far back in time grains can start, up to 1.4 s.
- `Detune`: random pitch variation per grain.
- `Reverse`: probability a grain plays backwards.
- `Feedback`: cloud recirculation into the buffer.
- `Width`: random stereo placement of grains.
- `Mix`: dry/wet blend.

## Factory presets

- `Dust Halo`: dense unison cloud for an ambient wash.
- `Octave Swarm`: octave-scattered grains with feedback.
- `Backwards Snow`: long shimmering grains, mostly reversed.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-glitter-grains-lv2
cmake --build build --target rtal-glitter-grains-standalone
cmake --build build --target rtal-glitter-grains-vst2
cmake --build build --target rtal-glitter-grains-package
```
