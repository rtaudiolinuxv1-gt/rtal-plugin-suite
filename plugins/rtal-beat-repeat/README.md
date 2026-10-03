# rtal-beat-repeat

`rtal-beat-repeat` is a performance beat repeat: hold the switch to loop the last slice in time, with decay and a falling-pitch glitch.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

While `Repeat` is held, the plugin keeps replaying the most recent slice of audio (a tempo-synced 1/4 down to 1/32 note) from its delay buffer, with short crossfades at the slice edges to avoid clicks. Each repeat can be quieter (`Decay`) and lower in pitch (`Pitch Drop`) for tape-wind-down glitches. Releasing the switch returns instantly to the live signal.

## Controls

- `Repeat`: hold to repeat the last slice.
- `BPM`: tempo, 40 to 240. Presets keep the tempo you set.
- `Slice`: 1/4, 1/8, 1/16, 1/32 or 1/8 triplet.
- `Decay`: level drop per repeat.
- `Pitch Drop`: semitones dropped per repeat, up to 1.5.
- `Slice Fade`: crossfade length at slice edges.
- `Mix`: repeat level against the live signal.

## Factory presets

- `Eighth Stutter`: classic eighth-note stutter.
- `Tape Wind-Down`: repeats that drop in pitch and fade.
- `Machine Gun`: fast 1/32 repeats.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-beat-repeat-lv2
cmake --build build --target rtal-beat-repeat-standalone
cmake --build build --target rtal-beat-repeat-vst2
cmake --build build --target rtal-beat-repeat-package
```
