# rtal-jet-wash

`rtal-jet-wash` is a through-zero tape flanger with a classic BBD-style mode, bipolar feedback, and LFO or picking-envelope sweeps.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

In through-zero mode the dry path is delayed to the centre of the sweep, and the inverted wet head travels across it. As the two delays cross, the comb filter collapses into complete cancellation and flips polarity, the jet-engine 'zero' of two tape machines flanged by hand. Classic mode sweeps a single delay above zero like a BBD flanger. The sweep can follow a triangle LFO or the picking envelope.

## Controls

- `Type`: Through-Zero or Classic.
- `Sweep`: LFO, or Envelope (each pick sweeps the comb).
- `Rate`: LFO speed, 0.02 Hz to 5 Hz.
- `Depth`: sweep range.
- `Manual`: centre delay, 0.3 ms to 6 ms.
- `Feedback`: bipolar: right of centre for ringing positive combs, left for hollow negative combs.
- `Spread`: stereo LFO offset.
- `Mix`: flanger depth; 0.5 gives the strongest notches.

## Factory presets

- `Tape Jet`: slow through-zero swoosh.
- `Metal Comb`: ringing classic flanger with heavy feedback.
- `Pick Swoosh`: envelope-swept through-zero flange on each note.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-jet-wash-lv2
cmake --build build --target rtal-jet-wash-standalone
cmake --build build --target rtal-jet-wash-vst2
cmake --build build --target rtal-jet-wash-package
```
