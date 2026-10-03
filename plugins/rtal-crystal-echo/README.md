# rtal-crystal-echo

`rtal-crystal-echo` is a pitch-climbing echo: every repeat is transposed again, so echoes rise or fall in octaves, fifths, fourths or thirds.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A granular pitch shifter sits inside the delay's feedback loop, so the first repeat is shifted once, the second twice, and so on. With +12 each echo rises an octave into crystalline sparkle; with -7 the echoes tumble down in fifths. `Pitch Blend` mixes unshifted feedback back in for a cascade that both repeats and climbs.

## Controls

- `Interval`: +12, +7, +5, +3, -5, -7 or -12 semitones per repeat.
- `Time`: delay time, 80 ms to 1.2 s.
- `Feedback`: number of repeats.
- `Pitch Blend`: shifted versus unshifted feedback.
- `Tone`: loop bandwidth.
- `Spread`: stereo time offset and cross-panning.
- `Mix`: dry/wet blend.

## Factory presets

- `Rising Octaves`: each echo an octave higher.
- `Falling Fifths`: echoes tumbling down in fifths.
- `Crystal Stairs`: fast minor-third staircase with some unshifted feedback.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-crystal-echo-lv2
cmake --build build --target rtal-crystal-echo-standalone
cmake --build build --target rtal-crystal-echo-vst2
cmake --build build --target rtal-crystal-echo-package
```
