# rtal-gamelan-bells

`rtal-gamelan-bells` is a modal resonator: each picked note strikes a tuned bell, gamelan gong, glass or marimba bar that rings at your pitch.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Eight resonant modes per material are tuned to the played note at the material's partial ratios. The church bell set has its hum tone an octave below, the minor-third tierce, the quint and the nominal above, while marimba bars use their strongly stretched overtones. The pitch is captured early in each note and held, so the bell keeps ringing in tune after the string stops. Each mode's bandwidth is set from the decay time, with higher modes dying faster unless Brightness is up. `Strike` excites the modes only with the pick transient, like a mallet.

## Controls

- `Material`: Bell, Gamelan, Glass or Marimba partial sets.
- `Tuning`: Tracked (rings at the played note) or Key Drone (fixed on the key).
- `Key`: key for Key Drone tuning.
- `Decay`: ring time, up to about 7 s.
- `Brightness`: upper-partial level and sustain.
- `Strike`: mallet-like transient excitation versus continuous excitation.
- `Spread`: stereo spread of the modes.
- `Mix`: dry/wet blend.

## Factory presets

- `Church Bell Lead`: long bell partials on every note.
- `Gamelan Shimmer`: bright gamelan metallophone.
- `Glass Harp`: long, bright glass tones.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-gamelan-bells-lv2
cmake --build build --target rtal-gamelan-bells-standalone
cmake --build build --target rtal-gamelan-bells-vst2
cmake --build build --target rtal-gamelan-bells-package
```
