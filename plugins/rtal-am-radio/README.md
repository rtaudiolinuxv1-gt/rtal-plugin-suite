# rtal-am-radio

`rtal-am-radio` turns your guitar into an old radio or telephone: band-limited speaker, tube grit, tuning drift, static and crackle.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A small-speaker band-pass with a resonant hump sets the voice, centred where you place `Band` and as wide as `Bandwidth`. A biased tube-style clipper adds grit. Tuning drift slowly wanders the filters and fades the station in and out, with static rising as the signal fades. Sparse crackle impulses ping a short resonator for authentic pops.

## Controls

- `Band`: centre of the speaker band.
- `Bandwidth`: width of the speaker band.
- `Grit`: tube distortion.
- `Tuning Drift`: station wander and fading.
- `Static`: hiss level, rising as the station fades.
- `Crackle`: pops and clicks.
- `Level`: output level.
- `Mix`: dry/wet blend.

## Factory presets

- `Kitchen Radio`: warm, slightly gritty tabletop radio.
- `Telephone`: narrow, distorted phone line.
- `Distant Station`: drifting, fading station with static and crackle.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-am-radio-lv2
cmake --build build --target rtal-am-radio-standalone
cmake --build build --target rtal-am-radio-vst2
cmake --build build --target rtal-am-radio-package
```
