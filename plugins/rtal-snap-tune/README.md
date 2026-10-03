# rtal-snap-tune

`rtal-snap-tune` is scale-snapping pitch correction for single-note lines, from gentle tuning help to the hard robotic snap.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A pitch tracker follows the note you play. Each moment's continuous pitch is compared with the nearest note allowed by the chosen key and scale, and a low-latency pitch shifter moves the guitar by the difference. `Retune Speed` at zero snaps instantly for the robotic stepped effect; higher values glide naturally, and `Tolerance` leaves notes alone when they are already close. Works on single notes, not chords.

## Controls

- `Key`: tonic of the scale.
- `Scale`: Chromatic, Major, Natural Minor, Minor Pentatonic, Major Pentatonic or Blues.
- `Retune Speed`: 0 is an instant robotic snap; higher is a natural glide.
- `Amount`: how much of the correction is applied.
- `Tolerance`: notes within this many cents are left alone.
- `Mix`: dry/wet blend.

## Factory presets

- `Robot Snap`: instant hard snap in the selected key and scale.
- `Gentle Tune`: slow, partial, tolerant correction.
- `Pentatonic Lock`: every note forced onto the minor pentatonic.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-snap-tune-lv2
cmake --build build --target rtal-snap-tune-standalone
cmake --build build --target rtal-snap-tune-vst2
cmake --build build --target rtal-snap-tune-package
```
