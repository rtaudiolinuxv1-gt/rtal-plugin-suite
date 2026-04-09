# rtal-silkcut-choir

`rtal-silkcut-choir` is a slide-sensitive choir doubler for guitar, aimed at vocal swells rather than simple chorus.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## Controls

- `Voices`: choir density.
- `Glide`: smoothing of slide movement.
- `Choir`: formant emphasis.
- `Silk`: softness and polish.
- `Drift`: slow detuned motion.
- `Width`: stereo field.
- `Mix`: dry/wet blend.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-silkcut-choir-lv2
cmake --build build --target rtal-silkcut-choir-standalone
cmake --build build --target rtal-silkcut-choir-vst2
cmake --build build --target rtal-silkcut-choir-package
```
