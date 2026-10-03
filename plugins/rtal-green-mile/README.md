# rtal-green-mile

`rtal-green-mile` is a mid-hump overdrive: only the mids and highs are driven into soft diode clipping, keeping lows tight and notes clear.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

As in the classic green overdrive, the op-amp gain stage only boosts frequencies above about 720 Hz, so the bass passes almost clean while the mids saturate. That is what keeps chords articulate and low notes tight. The clipper is an anti-aliased (ADAA) tanh diode pair, with asymmetric and hard options, followed by a mid hump and a sweepable treble roll-off.

## Controls

- `Drive`: gain of the mid/high stage.
- `Tone`: treble roll-off, 700 Hz to 5.6 kHz.
- `Level`: output level.
- `Tight`: pre-drive low cut.
- `Mid Push`: 720 Hz hump.
- `Clipping`: Symmetric, Asymmetric or Hard.

## Factory presets

- `Classic Push`: the classic mid-hump overdrive.
- `Blues Breaker-ish`: flatter, asymmetric, more open overdrive.
- `Tight Metal Boost`: low drive, tight lows and high level for pushing an amp.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-green-mile-lv2
cmake --build build --target rtal-green-mile-standalone
cmake --build build --target rtal-green-mile-vst2
cmake --build build --target rtal-green-mile-package
```
