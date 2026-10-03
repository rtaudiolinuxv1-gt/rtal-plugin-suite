# rtal-ice-age

`rtal-ice-age` is an infinite-sustain freeze pad: it captures each new chord into a frozen reverb tank and crossfades between layers, building a sustained bed under your playing.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Two lossless four-line feedback delay networks (orthogonal Hadamard mixing with allpass diffusion) alternate as capture tanks. When a new chord is detected, or the Hold switch is pressed, the idle tank opens its input for the capture window and then holds what it caught with feedback at or near 1.0. The output crossfades to the new layer while the previous tank fades out over the `Fade` time. With `Sustain` at maximum the hold is truly infinite.

## Controls

- `Capture`: Auto (captures each new chord) or Hold Switch (captures when Hold is switched on and releases when switched off).
- `Hold`: freeze switch for Hold Switch mode.
- `Sensitivity`: chord detection sensitivity in Auto mode.
- `Capture Time`: how long the tank listens after a trigger, 60 ms to 560 ms.
- `Fade`: crossfade and release time between layers.
- `Sustain`: how long a captured layer lasts; maximum is infinite.
- `Tone`: tank damping.
- `Pad Level`: frozen pad level.
- `Dry`: dry level.

## Factory presets

- `Chord Halo`: each chord leaves a soft, lasting halo.
- `Drone Bed`: infinite hold with long crossfades for drones.
- `Shoegaze Wall`: bright, dense frozen wall.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-ice-age-lv2
cmake --build build --target rtal-ice-age-standalone
cmake --build build --target rtal-ice-age-vst2
cmake --build build --target rtal-ice-age-package
```
