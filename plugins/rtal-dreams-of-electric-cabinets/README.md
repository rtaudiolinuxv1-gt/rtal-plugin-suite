# rtal-dreams-of-electric-cabinets

`rtal-dreams-of-electric-cabinets` is a cabinet and body sculptor for guitar, built around impossible speaker-box resonances instead of amp realism.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## Controls

- `Body`: low cabinet weight.
- `Cone`: upper-mid speaker character.
- `Box`: enclosure resonance.
- `Spark`: treble edge.
- `Warp`: unstable cabinet motion.
- `Room`: reflected tail.
- `Mix`: dry/wet blend.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-dreams-of-electric-cabinets-lv2
cmake --build build --target rtal-dreams-of-electric-cabinets-standalone
cmake --build build --target rtal-dreams-of-electric-cabinets-vst2
cmake --build build --target rtal-dreams-of-electric-cabinets-package
```
