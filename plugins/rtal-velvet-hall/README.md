# rtal-velvet-hall

`rtal-velvet-hall` is a lush modulated hall: an eight-line feedback delay network with early reflections, bloom and a gently chorused tail.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Eight delay lines of mutually prime lengths are cross-coupled through an orthogonal 8x8 Hadamard matrix, so energy is preserved in the mix and the decay is set purely by per-line loss gains computed from `Decay`. Each line is slowly and independently modulated, which smears metallic resonances into a smooth, chorused tail. Input allpass diffusion (`Bloom`) softens the attack, and a sparse early-reflection pattern scales with the room size.

## Controls

- `Size`: room size; scales every line and reflection.
- `Decay`: reverb time, about 0.6 s to 12 s.
- `Modulation`: depth of the tail's chorusing.
- `Bloom`: input diffusion; higher softens and slows the attack.
- `Early`: early reflection level.
- `High Damp`: high-frequency decay.
- `Pre-Delay`: 2 ms to 150 ms.
- `Mix`: dry/wet blend.

## Factory presets

- `Concert Hall`: natural, medium-large hall.
- `Chorused Void`: huge, heavily modulated space.
- `Dark Cathedral`: long, dark, slow-blooming tail.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-velvet-hall-lv2
cmake --build build --target rtal-velvet-hall-standalone
cmake --build build --target rtal-velvet-hall-vst2
cmake --build build --target rtal-velvet-hall-package
```
