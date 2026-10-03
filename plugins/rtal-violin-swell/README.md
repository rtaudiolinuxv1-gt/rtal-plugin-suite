# rtal-violin-swell

`rtal-violin-swell` is an automatic volume swell: every new note fades in from silence like a bowed instrument, with an optional ambient echo wash.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

An onset detector compares fast and slow envelopes to spot new notes. Each onset restarts a gain ramp from silence, shaped by `Curve` from a straight fade to a slow-start bowed swell. The audio runs 4 ms behind the detector so the pick click itself is muted. A small diffused stereo echo can be blended in to smear the swells into pads.

## Controls

- `Sensitivity`: onset detection sensitivity.
- `Rise`: swell time, 50 ms to 2.5 s.
- `Curve`: straight fade to slow-start swell.
- `Ambience`: echo wash level.
- `Space`: echo time and feedback.
- `Level`: output level.

## Factory presets

- `Slow Gear`: classic auto-swell.
- `Pedal Steel`: faster, steel-guitar-like swells with a little echo.
- `Cathedral Bow`: long bowed swells into a big ambient wash.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-violin-swell-lv2
cmake --build build --target rtal-violin-swell-standalone
cmake --build build --target rtal-violin-swell-vst2
cmake --build build --target rtal-violin-swell-package
```
