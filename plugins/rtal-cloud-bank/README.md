# rtal-cloud-bank

`rtal-cloud-bank` is a one-knob ambient machine: modulated echoes into a shimmering diffuse tank, with a freeze switch.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

`Atmosphere` drives everything at once: echo time and feedback, tank size and decay. The modulated stereo echoes feed a lossless four-line Hadamard tank with allpass diffusion, and an octave-up copy of the tank can be fed back in for shimmer. Switching `Freeze` mutes the input and shimmer and sets the tank's feedback to unity, holding the current cloud indefinitely while you play over it.

## Controls

- `Atmosphere`: macro control for echo and tank size and length.
- `Shimmer`: octave-up feedback into the tank.
- `Motion`: modulation of echoes and tank.
- `Tone`: brightness.
- `Freeze`: holds the current cloud.
- `Mix`: dry/wet blend.

## Factory presets

- `Morning Haze`: light, airy wash.
- `Night Cathedral`: huge, dark space.
- `Shimmer Storm`: bright, shimmering, moving cloud.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-cloud-bank-lv2
cmake --build build --target rtal-cloud-bank-standalone
cmake --build build --target rtal-cloud-bank-vst2
cmake --build build --target rtal-cloud-bank-package
```
