# rtal-crystal-pluck

`rtal-crystal-pluck` turns pick transients into glassy stereo flashes and metallic pluck reflections while leaving sustain relatively intact.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## Controls

- `Pluck`: transient enhancement amount.
- `Sparkle`: upper spectral brightness.
- `Glass`: resonator sharpness.
- `Scatter`: temporal spreading between crystal taps.
- `Decay`: flash length.
- `Width`: stereo fan-out.
- `Mix`: dry/wet blend.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-crystal-pluck-lv2
cmake --build build --target rtal-crystal-pluck-standalone
cmake --build build --target rtal-crystal-pluck-vst2
cmake --build build --target rtal-crystal-pluck-package
```
