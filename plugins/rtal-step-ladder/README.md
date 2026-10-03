# rtal-step-ladder

`rtal-step-ladder` is a tempo-synced 16-step sequenced ladder filter with glide, accent envelope and drive.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A bar-long phasor steps through one of eight 16-step cutoff patterns at the chosen tempo and division. The step value, smoothed by `Glide`, sets the cutoff of a Moog-style ladder filter over up to six octaves above `Base`, and the picking envelope can push it further for accents. A drive stage before the ladder adds acid-style grit.

## Controls

- `BPM`: tempo, 40 to 240. Presets keep the tempo you set.
- `Division`: 1/4, 1/8, 1/16 or 1/8 triplet steps.
- `Pattern`: Rise, Fall, Bounce, Acid, Gallop, Scatter, Pulse or Wave.
- `Base`: lowest cutoff.
- `Range`: sweep width, up to six octaves.
- `Resonance`: ladder resonance.
- `Glide`: smoothing between steps.
- `Accent`: how much picking dynamics push the cutoff.
- `Drive`: pre-filter saturation.
- `Mix`: dry/wet blend.

## Factory presets

- `Acid Rhythm`: squelchy sixteenth-note acid pattern.
- `Gallop Sweep`: galloping rhythmic filter.
- `Slow Wave Pad`: smooth, slow sine-shaped sweep.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-step-ladder-lv2
cmake --build build --target rtal-step-ladder-standalone
cmake --build build --target rtal-step-ladder-vst2
cmake --build build --target rtal-step-ladder-package
```
