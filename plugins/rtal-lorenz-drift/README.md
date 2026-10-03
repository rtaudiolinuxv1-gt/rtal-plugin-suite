# rtal-lorenz-drift

`rtal-lorenz-drift` is a chaotic modulator: a Lorenz attractor steers a resonant filter, pitch wobble and stereo position, and never repeats.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The Lorenz equations (the 'butterfly effect' system) are integrated sample by sample. Their three coordinates drive the filter cutoff, a delay-based pitch wobble and the stereo balance. At high `Chaos` the motion orbits one lobe of the butterfly and then flips unpredictably to the other, so the modulation is organic and never loops like an LFO. Lower `Chaos` settles into a decaying spiral.

## Controls

- `Speed`: how fast the system evolves.
- `Chaos`: system parameter rho: low settles, high is fully chaotic.
- `Filter Depth`: how far the attractor sweeps the filter.
- `Filter Center`: filter centre frequency.
- `Resonance`: filter resonance.
- `Pitch Depth`: chaotic pitch wobble.
- `Pan Depth`: chaotic stereo movement.
- `Mix`: dry/wet blend.

## Factory presets

- `Butterfly Filter`: chaotic resonant filter sweeps.
- `Unstable Tape`: chaotic pitch drift like a failing tape machine.
- `Chaos Orbit`: fast, wide, fully chaotic motion.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-lorenz-drift-lv2
cmake --build build --target rtal-lorenz-drift-standalone
cmake --build build --target rtal-lorenz-drift-vst2
cmake --build build --target rtal-lorenz-drift-package
```
