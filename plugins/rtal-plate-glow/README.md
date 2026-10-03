# rtal-plate-glow

`rtal-plate-glow` is a Dattorro plate reverb with pre-delay, input shimmer modulation, ducking and a tilt EQ.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The classic Dattorro plate topology provides dense, bright diffusion. Because the library plate has no internal modulation, `Motion` wobbles each channel's pre-delay with decorrelated slow LFOs and noise, which keeps sustained notes from sounding static. The wet signal can duck under your playing and is shaped by a tilt EQ around 900 Hz.

## Controls

- `Decay`: plate decay.
- `Pre-Delay`: 1 ms to 160 ms.
- `Diffusion`: input and tank diffusion.
- `Damping`: high-frequency loss.
- `Motion`: pre-delay modulation for movement.
- `Duck`: how much the plate steps back while you play.
- `Tilt`: darker or brighter plate.
- `Mix`: dry/wet blend.

## Factory presets

- `Studio Plate`: classic medium plate.
- `Ducked Vocal Plate`: longer plate that clears out while you play.
- `Endless Steel`: long, moving, bright plate.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-plate-glow-lv2
cmake --build build --target rtal-plate-glow-standalone
cmake --build build --target rtal-plate-glow-vst2
cmake --build build --target rtal-plate-glow-package
```
