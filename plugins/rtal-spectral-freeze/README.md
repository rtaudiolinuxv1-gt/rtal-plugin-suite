# rtal-spectral-freeze

`rtal-spectral-freeze` holds any moment of your playing as an endless frozen spectrum and morphs smoothly between two frozen chords, with diffusion, shimmer, pitch shift and a reverb wash.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Capture.** A capture stores, per frequency bin of a 4096-point FFT, the magnitude (averaged over several frames when Blur is up) and the instantaneous frequency measured by the phase vocoder, so frozen notes keep their exact pitch. Captures happen with the buttons, or automatically on every new note: either always into A, or alternating between A and B. Automatic captures skip the pick attack and take the body of the note.

**Playback.** Each frame is rebuilt from the stored spectra, and every bin's phase advances at its own frequency. Morphing blends the two captures, part geometrically (a true spectral morph) and part linearly (so an empty slot fades rather than vanishes), and each bin's frequency follows the louder capture. Diffusion adds random phase, smearing the freeze into a wash. Shimmer lets each bin's level drift slowly. Shift moves the whole spectrum by semitones, and Tilt darkens or brightens it.

**Stereo and randomness.** Left and right use independent random phases, so the freeze is wide. The randomness is seeded fresh on every plugin activation.

In *Alternate A and B* mode the morph glides towards each new capture over the Auto Glide time, so a chord progression melts from one chord into the next.

## Controls

- `Factory Preset`: Manual keeps every control live.
- `Capture A / Capture B`: Freeze the next moment into a slot.
- `Clear`: Empty both slots.
- `Auto Capture`: Off, Every New Note to A, or Alternate A and B.
- `Sensitivity`: How quiet a new note can be and still trigger an automatic capture.
- `Blur`: Averages up to 16 frames into a capture for a smoother, less articulate freeze.
- `A Holding / B Holding`: Meters showing which slots hold a capture.
- `Morph A to B`: Position between the captures (manual modes).
- `Auto Glide`: Glide time towards each new capture in Alternate mode.
- `LFO Rate / LFO Depth`: Slow automatic morphing.
- `Diffusion`: Random phase: from glassy and exact to a smeared wash.
- `Shimmer`: Slow random level drift per bin.
- `Shift`: Pitch shift of the frozen sound in semitones.
- `Tilt (Dark to Bright)`: Spectral tilt.
- `Wash`: Reverb on the frozen layer.
- `Freeze Level / Swell / Dry Level`: Mix; Swell fades the freeze in after a capture.

## Factory presets

- `Manual`: Every control as set by hand.
- `Chord Pad`: Every new chord becomes a soft pad under your playing.
- `Evolving Morph`: Alternating captures that melt into each other, with a slow LFO.
- `Octave Halo`: Frozen chords an octave up.
- `Dark Drone`: An octave down, dark tilt, heavy shimmer.
- `Frozen Glass`: Bright, diffuse, octave-up shimmer.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-spectral-freeze-lv2
cmake --build build --target rtal-spectral-freeze-standalone
cmake --build build --target rtal-spectral-freeze-vst2
cmake --build build --target rtal-spectral-freeze-package
```
