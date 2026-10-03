# rtal-sub-orbit

`rtal-sub-orbit` is an analog-style octaver with one and two octaves down from flip-flop dividers plus a rectified octave up.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The fundamental is isolated with a lowpass, then a Schmitt trigger with an envelope-tracking threshold turns it into clean edges. Two toggle flip-flops divide the frequency by two and four. The resulting square waves are shaped by the input envelope and rounded by the sub filter, as in classic analog octave dividers. Full-wave rectification of the input gives the octave up.

## Controls

- `Dry`: dry level.
- `Sub 1`: one octave down.
- `Sub 2`: two octaves down.
- `Octave Up`: rectified octave up.
- `Sub Tone`: sub filter; low is round and sine-like, high is buzzy.
- `Grit`: lets more of the square edge through and roughens the octave up.
- `Tracking`: pitch-detection filter and threshold. Lower for low strings, higher for leads.

## Factory presets

- `Bass Shadow`: clean bass-guitar sub doubling.
- `Synth Floor`: both subs with grit for synth-bass lines.
- `Octave Fuzz`: fuzzy octave up with a sub underneath.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-sub-orbit-lv2
cmake --build build --target rtal-sub-orbit-standalone
cmake --build build --target rtal-sub-orbit-vst2
cmake --build build --target rtal-sub-orbit-package
```
