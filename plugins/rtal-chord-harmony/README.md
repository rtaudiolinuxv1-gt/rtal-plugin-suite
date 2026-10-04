# rtal-chord-harmony

`rtal-chord-harmony` is a chord-aware polyphonic harmonizer. It recognises the chord you strum and moves every note to other tones of that chord, so a strummed chord comes back as a new inversion of the same chord instead of a clashing parallel copy. Single notes played over the chord are harmonised inside it too.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Analysis.** A spectral engine (`rtal_chord_harmony.h`) takes a 4096-point FFT every 512 samples. Each frame is reduced to its spectral peaks, and their frequencies are refined with the phase vocoder.

**Chord recognition.** The peaks build a pitch-class profile, which is matched against major, minor, dominant 7, major 7, minor 7, sus2, sus4, diminished, augmented and power-chord templates. The bass note gets a bonus. Smoothing and hysteresis stop the detected chord from flickering, and the chord is held through silence, so you can strum a chord and then solo over it. `Chord Source` can also lock a chord by hand.

**Harmony.** For each voice, every peak is moved to the chord tone the chosen number of chord steps away. Notes that are not chord tones move along the matching chord scale (Ionian, Dorian, Mixolydian and so on). Upper partials that are not chord tones travel with their fundamental, which keeps notes harmonic. Peaks are moved by phase-locked region shifting: the whole lobe around each peak moves together, and its phase advances at the exact target frequency, so the pitch stays precise even on low strings.

**Latency.** The harmony voices arrive about 85 ms after the dry signal; that window is what it takes to tell the notes of a chord apart. `Looseness` adds a slowly wandering extra delay so the harmonies sit like a second player.

## Controls

- `Factory Preset`: Manual keeps every control live; the presets set both voices and the looseness.
- `Chord Source`: Detect (follow your playing) or Manual.
- `Manual Root / Manual Chord`: The chord used in Manual mode.
- `Sensitivity`: How quiet a note can be and still count (sets the peak floor from -50 to -90 dBFS).
- `Reference A`: Tuning reference for note naming.
- `Voice 1 / Voice 2 Interval`: How many chord tones up or down each voice moves (Same Note plus Octave makes an octave voice; Same Note with Octave 0 turns the voice off).
- `Voice 1 / Voice 2 Octave`: Extra octave shift, -2 to +1.
- `Voice 1 / Voice 2 Level, Pan`: Level and stereo position of each voice.
- `Looseness`: Slow random timing drift of the voices, up to 25 ms.
- `Dry Level / Harmony Level`: Mix of the original and the harmonies.
- `Detected Root, Chord, Confidence`: Meters showing what the engine hears.

## Factory presets

- `Manual`: Every control as set by hand.
- `Third Above`: One voice, one chord tone up.
- `Chord Choir`: One chord tone up and one down, panned wide.
- `Stacked Inversions`: One and two chord tones up.
- `Low Harmony`: One chord tone down, plus two down an octave lower.
- `Octave Halo`: The same notes an octave up and an octave down.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-chord-harmony-lv2
cmake --build build --target rtal-chord-harmony-standalone
cmake --build build --target rtal-chord-harmony-vst2
cmake --build build --target rtal-chord-harmony-package
```
