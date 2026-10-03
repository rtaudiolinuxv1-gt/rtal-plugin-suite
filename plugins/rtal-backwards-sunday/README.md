# rtal-backwards-sunday

`rtal-backwards-sunday` is a reverse delay: phrases come back played backwards, with an octave-up reverse mode and a reverse-plus-forward mode.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Two read heads sweep backwards through the delay buffer half a cycle apart, each faded in and out with complementary raised-cosine windows so their sum is always unity. In `Reverse Octave` mode the heads read backwards at double speed for a reversed octave-up shimmer. In `Reverse + Forward` mode a normal echo is added to the loop, and the loop gain is normalised so feedback stays stable.

## Controls

- `Mode`: Reverse, Reverse Octave, or Reverse + Forward.
- `Time`: reverse window length, 150 ms to 1.5 s.
- `Feedback`: repeats of the reversed phrase.
- `Smear`: crossfade length between reversed chunks; higher is smoother and more washed out.
- `Tone`: feedback and output bandwidth.
- `Width`: stereo window offset and channel separation.
- `Mix`: dry/wet blend.

## Factory presets

- `Tomorrow Never`: classic psychedelic reverse guitar.
- `Rewind Bells`: reversed octave-up chunks.
- `Mirror Pad`: long, smeared reverse and forward wash.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-backwards-sunday-lv2
cmake --build build --target rtal-backwards-sunday-standalone
cmake --build build --target rtal-backwards-sunday-vst2
cmake --build build --target rtal-backwards-sunday-package
```
