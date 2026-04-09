# rtal-dynamic-distortion

`rtal-dynamic-distortion` is a touch-reactive drive for guitar. It shifts saturation density, bias, and focus with playing dynamics instead of staying static.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## Controls

- `Drive`: core gain staging.
- `Touch`: how much picking dynamics reshape the distortion.
- `Focus`: resonant mid focus before clipping.
- `Bias`: asymmetry and odd-harmonic shift.
- `Gate`: noise-floor cleanup.
- `Output`: post-drive level.
- `Mix`: dry/wet blend.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-dynamic-distortion-lv2
cmake --build build --target rtal-dynamic-distortion-standalone
cmake --build build --target rtal-dynamic-distortion-vst2
cmake --build build --target rtal-dynamic-distortion-package
```
