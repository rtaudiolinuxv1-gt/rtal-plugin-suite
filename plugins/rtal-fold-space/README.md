# rtal-fold-space

`rtal-fold-space` is a west-coast wavefolder distortion: anti-aliased sine folding, symmetry, pick dynamics and a resonant colour filter.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The input is driven into a sine wavefolder. Instead of clipping, peaks fold back on themselves and create the bright, vocal harmonics of west-coast synthesizers. The folder uses first-order antiderivative anti-aliasing (the mean of sin over each sample step) to keep aliasing down without oversampling. `Symmetry` biases the fold for even harmonics, `Dynamics` lets picking intensity add folds, and a resonant state-variable lowpass shapes the result.

## Controls

- `Folds`: how many times the wave folds over.
- `Symmetry`: fold bias; off-centre adds even harmonics.
- `Dynamics`: how much picking intensity adds folds.
- `Color`: colour filter cutoff.
- `Resonance`: colour filter resonance.
- `Level`: output level.
- `Mix`: dry/wet blend.

## Factory presets

- `Buchla Bounce`: dynamic, bouncy folding.
- `Glass Tongue`: gentle asymmetric folds with a resonant peak.
- `Fold Storm`: deep folding for aggressive synth-like leads.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-fold-space-lv2
cmake --build build --target rtal-fold-space-standalone
cmake --build build --target rtal-fold-space-vst2
cmake --build build --target rtal-fold-space-package
```
