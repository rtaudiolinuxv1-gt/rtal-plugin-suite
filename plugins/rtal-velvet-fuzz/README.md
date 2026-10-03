# rtal-velvet-fuzz

`rtal-velvet-fuzz` is a two-stage fuzz with bias starve, sputter gate, octave fuzz and a scoopable Muff-style tone stack. The clippers are anti-aliased.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Both clipping stages use first-order antiderivative anti-aliasing (ADAA) of tanh, which strongly reduces the aliasing fizz that plain digital clippers produce without oversampling. `Starve` shifts the transistor bias for lopsided, gated, dying-battery fuzz. A rectifier ahead of the clipper gives octave fuzz, and the tone stack blends lowpass and highpass paths with an adjustable mid scoop.

## Controls

- `Fuzz`: gain into both stages.
- `Starve`: bias shift for sputtery, asymmetric clipping.
- `Gate`: sputter gate threshold.
- `Octave`: rectified octave-up blend.
- `Tone`: dark to bright across the scooped tone stack.
- `Mids`: fills the mid scoop back in.
- `Level`: output level.

## Factory presets

- `Round Face`: warm, mid-forward vintage fuzz.
- `Muffin Wall`: scooped sustaining wall of fuzz.
- `Velcro Splatter`: starved, gated, octave-tinged splatter.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-velvet-fuzz-lv2
cmake --build build --target rtal-velvet-fuzz-standalone
cmake --build build --target rtal-velvet-fuzz-vst2
cmake --build build --target rtal-velvet-fuzz-package
```
