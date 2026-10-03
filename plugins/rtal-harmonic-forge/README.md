# rtal-harmonic-forge

`rtal-harmonic-forge` is a harmonic mixer: Chebyshev waveshaping adds exactly the 2nd, 3rd, 4th and 5th harmonics you dial in.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Chebyshev polynomials have a neat property: fed a full-scale sine, T2 returns exactly its second harmonic, T3 its third, and so on. `Focus` isolates the guitar's fundamental, an envelope follower normalises it to full scale, and each harmonic's polynomial is mixed in at its own level before the original level is restored. Content above the focus band passes through untouched. The result is more like drawbars for harmonics than a distortion pedal.

## Controls

- `Fundamental`: level of the original fundamental.
- `2nd`: second harmonic (octave): warm, even.
- `3rd`: third harmonic (octave and fifth): hollow, reedy.
- `4th`: fourth harmonic (two octaves).
- `5th`: fifth harmonic (two octaves and a major third).
- `Focus`: fundamental isolation filter.
- `Mix`: dry/wet blend.

## Factory presets

- `Tube Warmth`: mostly 2nd harmonic for a warm, even glow.
- `Hollow Clarinet`: odd harmonics only, for a reedy, hollow tone.
- `Bright Organ`: all harmonics up for an organ-like stack.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-harmonic-forge-lv2
cmake --build build --target rtal-harmonic-forge-standalone
cmake --build build --target rtal-harmonic-forge-vst2
cmake --build build --target rtal-harmonic-forge-package
```
