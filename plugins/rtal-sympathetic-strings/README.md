# rtal-sympathetic-strings

`rtal-sympathetic-strings` adds a bank of six tuned strings that ring sympathetically with your playing, like the drone strings of a sitar or the undamped strings of a harp.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Six Karplus-Strong string models are tuned to a chord built on the selected key, rooted between C2 and B2. The input excites them through a pick-sensitive soft clipper, so notes that belong to the chord bloom while others only shimmer. Decay time is set per string from `Resonance`, and slow detune drift keeps the bank alive.

## Controls

- `Key`: root note of the string bank.
- `Chord`: Major, Minor, Sus4, Power, Maj7, Min7 or Raga Drone voicing.
- `Resonance`: string decay time, 0.4 s to 12 s.
- `Brightness`: string damping; higher is brighter and more metallic.
- `Excite`: how hard the guitar drives the strings, with emphasis on pick attack.
- `Shimmer`: slow detune drift between strings.
- `Width`: alternating stereo placement of the strings.
- `Mix`: dry/wet blend.

## Factory presets

- `Sitar Room`: bright raga drone with fast decay. Uses the selected key.
- `Harp Halo`: soft, wide halo using the selected key and chord.
- `Drone Temple`: long power-chord drone with heavy shimmer.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-sympathetic-strings-lv2
cmake --build build --target rtal-sympathetic-strings-standalone
cmake --build build --target rtal-sympathetic-strings-vst2
cmake --build build --target rtal-sympathetic-strings-package
```
