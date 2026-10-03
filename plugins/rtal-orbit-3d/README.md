# rtal-orbit-3d

`rtal-orbit-3d` is a binaural spatializer for headphones: the guitar orbits your head, swings like a pendulum or sits anywhere around you, using interaural time, level and head-shadow cues.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

For each source angle the far ear receives the sound up to 0.66 ms later (interaural time difference), quieter (level difference), and darker through a head-shadow lowpass. Sources behind the listener lose a little extra treble. `Distance` lowers the direct level and brings in a few early reflections. Best heard on headphones.

## Controls

- `Motion`: Orbit (circles the head), Pendulum (swings across the front) or Static.
- `Rate`: motion speed.
- `Azimuth`: position offset; centre is straight ahead, a quarter turn right is the right ear.
- `Span`: pendulum swing width; in Orbit mode, how far the circle reaches to the sides.
- `Cue Depth`: strength of the binaural cues.
- `Distance`: how far away the guitar sounds.
- `Room`: early reflection level.
- `Mix`: dry/wet blend.

## Factory presets

- `Slow Halo`: slow full orbit.
- `Pendulum Front`: side-to-side swing in front of you.
- `Fast Whirl`: fast orbit, like a spinning speaker around your head.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-orbit-3d-lv2
cmake --build build --target rtal-orbit-3d-standalone
cmake --build build --target rtal-orbit-3d-vst2
cmake --build build --target rtal-orbit-3d-package
```
