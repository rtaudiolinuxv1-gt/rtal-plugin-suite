# rtal-passing-train

`rtal-passing-train` is a Doppler fly-by: your guitar races past the listener along a track, with true Doppler pitch, distance attenuation and air absorption.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The source swings along a straight track on a smooth path, passing the listener at the chosen closest distance. The sound reaches the listener through a delay equal to the distance divided by the speed of sound, so the Doppler pitch rise and fall comes out of the physics rather than a pitch shifter. Level falls with distance (softened so the far ends stay audible), air absorption darkens the far ends, and the stereo position follows the angle to the source.

## Controls

- `Speed`: peak speed, 10 km/h to 300 km/h.
- `Distance`: closest approach, 1 m to 40 m.
- `Track Length`: length of the track.
- `Width`: stereo width of the pass.
- `Air Absorption`: high-frequency loss with distance.
- `Mix`: dry/wet blend.

## Factory presets

- `Express Train`: fast passes on a long track.
- `Race Car`: very fast, close fly-bys.
- `Lazy Swing`: slow, close swinging motion.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-passing-train-lv2
cmake --build build --target rtal-passing-train-standalone
cmake --build build --target rtal-passing-train-vst2
cmake --build build --target rtal-passing-train-package
```
