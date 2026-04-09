# rtal-In_Bloom

`rtal-In_Bloom` is a resonant bloom effect for guitar. It turns picked notes into a tuned cloud of sympathetic strings and soft high-frequency air.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## Controls

- `Bloom`: overall bloom intensity.
- `Resonance`: resonator sharpness and ring.
- `Air`: top-end shimmer.
- `Spread`: interval spacing between bloom voices.
- `Decay`: bloom tail length.
- `Width`: stereo motion.
- `Mix`: dry/wet blend.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-In_Bloom-lv2
cmake --build build --target rtal-In_Bloom-standalone
cmake --build build --target rtal-In_Bloom-vst2
cmake --build build --target rtal-In_Bloom-package
```
