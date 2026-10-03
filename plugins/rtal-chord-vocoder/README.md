# rtal-chord-vocoder

`rtal-chord-vocoder` is a sixteen-band vocoder: your guitar articulates a synth chord pad, fixed in a key or following the note you play.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The guitar is analysed by sixteen bandpass filters from 110 Hz to 7.5 kHz, and the energy in each band shapes the same band of an internal carrier: four detuned-saw chord voices plus optional breath noise. Your picking, palm muting and tone changes animate the chord the way a voice animates a classic vocoder. In Tracked mode the chord root follows the note you play, folded into the chosen octave, with the chosen chord quality on top. All bands are normalised to unity peak.

## Controls

- `Root`: Key (chord fixed on the key) or Tracked (chord root follows your note).
- `Key`: key for the chord root.
- `Chord`: Major, Minor, Sus2, Power, Maj7 or Min7.
- `Octave`: Low, Mid or High carrier register.
- `Formant Sharpness`: band Q; higher is more vocal and robotic.
- `Release`: how long each band rings after the guitar.
- `Breath`: noise in the carrier for consonant-like edges.
- `Vocoder Level`: vocoder level.
- `Dry`: guitar level.

## Factory presets

- `Robot Strings`: classic vocoded chord on the selected key and chord.
- `Following Choir`: major chords that follow your melody.
- `Whisper Pad`: breathy, high maj7 pad with long release.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-chord-vocoder-lv2
cmake --build build --target rtal-chord-vocoder-standalone
cmake --build build --target rtal-chord-vocoder-vst2
cmake --build build --target rtal-chord-vocoder-package
```
