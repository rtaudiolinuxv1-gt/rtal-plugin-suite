# rtal-stutter-gate

`rtal-stutter-gate` is a sixteen-step rhythmic slicer with a pattern bank, swing, duty cycle and stereo ping-pong.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A bar-long phasor driven by the `BPM` control and the selected division picks one of sixteen steps. Each pattern is a 16-bit mask, swing stretches the first step of each pair, and duty sets how long each open step stays open. Gate edges are smoothed to avoid clicks.

## Controls

- `BPM`: tempo, 40 to 240. Presets keep the tempo you set.
- `Division`: 1/8, 1/16, 1/16 triplet or 1/32 steps.
- `Pattern`: Straight, Gallop, Offbeat, Trance, Broken, Stutter, Sparse or Sixteenths.
- `Depth`: how far closed steps are attenuated.
- `Duty`: portion of each open step that is open.
- `Smooth`: gate edge time, from clicky-tight to soft.
- `Swing`: delays every second step.
- `Ping Pong`: sends alternate steps to alternate sides.

## Factory presets

- `Trance Chop`: classic trance gate.
- `Gallop Gate`: galloping metal rhythm.
- `Ping Pong Glitch`: fast broken pattern bouncing between speakers.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-stutter-gate-lv2
cmake --build build --target rtal-stutter-gate-standalone
cmake --build build --target rtal-stutter-gate-vst2
cmake --build build --target rtal-stutter-gate-package
```
