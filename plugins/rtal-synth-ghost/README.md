# rtal-synth-ghost

`rtal-synth-ghost` is a monophonic guitar synth: it tracks your pitch and plays a saw or square oscillator through an enveloped ladder filter.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A pitch tracker follows single-note lines, quantises them to the nearest semitone (so the synth stays in tune) and glides between notes. Band-limited saw and pulse oscillators follow the guitar's amplitude, and each new pick fires a filter envelope into a Moog-style ladder for classic synth plucks and swells. Play single notes; chords confuse the tracker.

## Controls

- `Wave`: Saw, Square, Saw + Sub (octave-down square) or Pulse Wide (25% pulse).
- `Octave`: -2, -1, 0 or +1 octave.
- `Glide`: portamento time.
- `Cutoff`: base filter cutoff.
- `Resonance`: ladder resonance.
- `Filter Env`: how far each pick opens the filter.
- `Env Decay`: filter envelope decay.
- `Synth Level`: synth level.
- `Dry`: guitar level.

## Factory presets

- `Fat Bass Lead`: saw plus sub, an octave down, with a plucky filter.
- `Square Chiptune`: bright square an octave up.
- `Brass Swell`: slow-opening saw brass.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-synth-ghost-lv2
cmake --build build --target rtal-synth-ghost-standalone
cmake --build build --target rtal-synth-ghost-vst2
cmake --build build --target rtal-synth-ghost-package
```
