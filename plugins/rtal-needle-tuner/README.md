# rtal-needle-tuner

`rtal-needle-tuner` is a chromatic tuner with note, octave and cents meters, an adjustable reference pitch and a mute switch for silent tuning.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A coarse zero-crossing pitch estimate picks a lowpass that isolates the string's fundamental; the cutoff is snapped to the coarse note with hysteresis so it stays still while a note rings. The fine reading then times every cycle between upward zero crossings with sub-sample interpolation, averages the per-cycle frequency, and snaps instantly to new notes. In offline tests on pure tones across E2 to E6 the reading settles to within about 1 cent in under a second.

## Controls

- `Mute`: silences the output while you tune.
- `Reference A`: A4 reference, 425 Hz to 455 Hz.
- `Needle Speed`: steadier or faster needle.
- `Note (0=C ... 11=B)`: detected note.
- `Octave`: detected octave.
- `Cents`: deviation from the nearest note, -50 to +50.
- `Frequency`: detected frequency in Hz.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-needle-tuner-lv2
cmake --build build --target rtal-needle-tuner-standalone
cmake --build build --target rtal-needle-tuner-vst2
cmake --build build --target rtal-needle-tuner-package
```
