# rtal-twelve-string

`rtal-twelve-string` simulates a twelve-string guitar: octave courses on the low strings, detuned unison courses, and pick-timing spread between the paired strings.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

On a real twelve-string only the four lower courses carry an octave string, so the octave voice is pitch shifted from the low-passed part of the guitar (`Octave Focus` sets how much). Two slightly detuned unison voices model the doubled strings, each delayed by a few milliseconds as the pick reaches the second string of each course. A high shelf adds the chime of the thin octave strings.

## Controls

- `Octave Course`: level of the octave strings.
- `Octave Focus`: how far up the neck the octave strings reach.
- `Unison Course`: level of the detuned unison strings.
- `Detune`: detune of the paired strings.
- `Pick Lag`: delay between the strings of each course, 2 ms to 16 ms.
- `Chime`: brightness of the added strings.
- `Width`: stereo spread.
- `Mix`: dry/wet blend.

## Factory presets

- `Jangle Pop`: bright jangle.
- `Folk Strum`: warm, wide strumming.
- `Psychedelic Chime`: shimmering, detuned and very wide.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-twelve-string-lv2
cmake --build build --target rtal-twelve-string-standalone
cmake --build build --target rtal-twelve-string-vst2
cmake --build build --target rtal-twelve-string-package
```
