# rtal-poly-synth

`rtal-poly-synth` is a polyphonic guitar synth. It picks the separate notes out of the chords you play, up to six at once, and gives each string its own synth voice with oscillators, a ladder filter and envelopes.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Note detection.** The engine (`rtal_poly_synth.h`) takes a 4096-point FFT every 512 samples and finds the spectral peaks. It then extracts notes one at a time (iterative multi-pitch estimation): every candidate fundamental is scored by how much harmonic energy it explains; the best one is taken; the peaks it explains are attenuated; and the search repeats. Candidates near a note already found are rejected. Upper harmonics of a found note need extra evidence before they count as notes of their own, which keeps octave errors rare. Notes an octave or a twelfth above another note in the chord are often absorbed into the lower note, and the synth voice's own harmonics cover them.

**Voice tracking.** Detected notes are matched to the six voice slots by pitch, so a held chord keeps each string on its own voice, and a bend glides that voice only. A new note must persist for two frames before it takes a voice; a note that disappears is released.

**Synth voices.** Each voice has two detuned saws morphing to a pulse, a sub-octave square, and an ADSR envelope with optional pick dynamics. It runs through a ladder filter with envelope amount and key tracking. Pitch Snap pulls each voice towards the nearest semitone. The analysis adds roughly 40 ms of latency to the synth.

## Controls

- `Factory Preset`: Manual keeps every control live; the presets set oscillators, filter and envelopes.
- `Sensitivity`: Detection floor for quiet notes.
- `Max Notes`: Upper limit on simultaneous voices (1-6).
- `Pitch Snap`: 0 follows bends and vibrato exactly, 1 quantises to the nearest semitone.
- `Glide`: Portamento time when a voice changes pitch.
- `Octave`: Synth octave relative to the guitar.
- `Reference A`: Tuning reference for Pitch Snap.
- `Saw to Square, Pulse Width, Detune, Sub Octave`: Oscillator shape and thickness.
- `Cutoff, Resonance, Envelope Amount, Key Tracking`: Ladder filter.
- `Attack, Decay, Sustain, Release`: Voice envelope.
- `Pick Dynamics`: How much each voice follows how hard its string sounds.
- `Stereo Spread`: Voices are spread across the stereo field (the first voice sits centre).
- `Synth Level / Guitar Level`: Mix.
- `Notes Playing`: Meter of active voices.

## Factory presets

- `Manual`: Every control as set by hand.
- `Poly Pad`: Slow, detuned, warm pad.
- `Brass Section`: Punchy filter envelope on saws.
- `Square Organ`: Snapped square-wave organ.
- `Sub Bass Synth`: An octave down with a heavy sub.
- `Glass Keys`: An octave up, bright pluck with a long release.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-poly-synth-lv2
cmake --build build --target rtal-poly-synth-standalone
cmake --build build --target rtal-poly-synth-vst2
cmake --build build --target rtal-poly-synth-package
```
