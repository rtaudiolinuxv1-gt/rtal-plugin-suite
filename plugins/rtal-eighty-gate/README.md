# rtal-eighty-gate

`rtal-eighty-gate` is an eighties gated reverb and reverse-gate: a huge room chopped off by a gate keyed from your playing.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A long Zita-style hall runs continuously, and a gate keyed by onset detection on the dry signal decides how much of it you hear. In `Gated` mode the room snaps open on each hit, stays flat for the gate time, then is cut off over the release time, the big-drum sound of the eighties. In `Reverse` mode the gate swells up through the gate time before cutting, like a reversed reverb.

## Controls

- `Shape`: Gated or Reverse.
- `Size`: decay of the underlying room.
- `Gate Time`: how long the gate stays open, 80 ms to 780 ms.
- `Gate Release`: how quickly the gate closes.
- `Sensitivity`: hit detection sensitivity.
- `Tone`: room brightness and low cut.
- `Mix`: dry/wet blend.

## Factory presets

- `Big Snare Room`: huge gated room.
- `Reverse Gate`: swelling reverse-gated room.
- `Tight Ambience`: short gated ambience that thickens without washing out.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-eighty-gate-lv2
cmake --build build --target rtal-eighty-gate-standalone
cmake --build build --target rtal-eighty-gate-vst2
cmake --build build --target rtal-eighty-gate-package
```
