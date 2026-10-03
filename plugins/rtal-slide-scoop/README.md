# rtal-slide-scoop

`rtal-slide-scoop` adds automatic pitch gestures: every note scoops up into pitch, dives in from above, or falls off as it decays.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

An onset detector restarts a pitch gesture on every new note. Scoop starts the note below pitch and slides up, Dive In starts above and slides down, and Fall Off drops the pitch as the note dies away, like a slide player or a singer. A short lookahead makes sure the very start of each note is inside the gesture.

## Controls

- `Gesture`: Scoop Up, Dive In, Fall Off, or Scoop and Fall.
- `Depth`: gesture size, 0.25 to 12 semitones.
- `Glide Time`: how long the scoop or dive takes.
- `Curve`: gesture shape; higher settles faster at the end.
- `Sensitivity`: note detection sensitivity.
- `Mix`: dry/wet blend.

## Factory presets

- `Steel Scoop`: subtle pedal-steel-style scoop.
- `Drunk Slide`: scoop in and fall off every note.
- `Fall Off Blues`: deep fall-offs as notes decay.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-slide-scoop-lv2
cmake --build build --target rtal-slide-scoop-standalone
cmake --build build --target rtal-slide-scoop-vst2
cmake --build build --target rtal-slide-scoop-package
```
