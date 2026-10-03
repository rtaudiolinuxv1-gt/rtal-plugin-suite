# rtal-cathedral-shimmer

`rtal-cathedral-shimmer` is a shimmer reverb: a large hall whose tail is pitch-shifted and fed back into itself, so notes bloom into octaves and fifths.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A Zita-style FDN hall runs inside an outer feedback loop that contains a two-window granular pitch shifter, a tone filter and a soft limiter. Each pass through the loop raises the tail by the chosen interval, building cascades of harmonics. Feedback is normalised against the hall's decay time so long tails stay bounded. Channels swap on the way back for a wider image.

## Controls

- `Interval`: +12, +7, +19, +24 or -12 semitones.
- `Size`: hall decay, about 1 s to 15 s.
- `Shimmer`: pitch-shifted feedback amount.
- `Damping`: high-frequency decay in the hall.
- `Pre-Delay`: 5 ms to 250 ms before the hall.
- `Shimmer Tone`: brightness of the shimmer loop.
- `Mix`: dry/wet blend.

## Factory presets

- `Heaven Octave`: classic octave-up shimmer.
- `Fifth Cathedral`: fifths cascading into the hall.
- `Abyss Choir`: octave-down shimmer in a huge dark space.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-cathedral-shimmer-lv2
cmake --build build --target rtal-cathedral-shimmer-standalone
cmake --build build --target rtal-cathedral-shimmer-vst2
cmake --build build --target rtal-cathedral-shimmer-package
```
