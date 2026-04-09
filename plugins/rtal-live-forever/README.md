# rtal-live-forever

`rtal-live-forever` is a controlled feedback generator for guitar. It aims for singing endless-note behavior without needing stage volume.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## Controls

- `Excite`: how hard input energy feeds the feedback voice.
- `Sustain`: hold time and loop-gain feel.
- `Focus`: pitch-center sharpness.
- `Rise`: time before feedback blooms.
- `Glow`: upper harmonic shine.
- `Width`: stereo movement.
- `Mix`: dry/wet blend.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-live-forever-lv2
cmake --build build --target rtal-live-forever-standalone
cmake --build build --target rtal-live-forever-vst2
cmake --build build --target rtal-live-forever-package
```
