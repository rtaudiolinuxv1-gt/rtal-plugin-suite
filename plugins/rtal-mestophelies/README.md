# rtal-mestophelies

`rtal-mestophelies` is a chord ghost and afterimage effect. It smears guitar material into drifting harmonic traces rather than a conventional delay wash.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## Controls

- `Shadow`: ghost layer intensity.
- `Smear`: delay-space density.
- `Drift`: slow movement in the ghost taps.
- `Tension`: harmonic sharpness.
- `Tail`: release length.
- `Width`: stereo spread.
- `Mix`: dry/wet blend.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-mestophelies-lv2
cmake --build build --target rtal-mestophelies-standalone
cmake --build build --target rtal-mestophelies-vst2
cmake --build build --target rtal-mestophelies-package
```
