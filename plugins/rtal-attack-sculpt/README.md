# rtal-attack-sculpt

`rtal-attack-sculpt` is a level-independent transient shaper that boosts or softens pick attack and note sustain separately.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Two pairs of envelope followers compare fast and slow behaviour. A fast-attack follower runs ahead of a slow-attack one at every pick, and that difference (in dB) drives the attack gain. A slow-release follower outlasts a fast-release one as notes decay, and that difference drives the sustain gain. Because both work on level differences, the effect responds the same whether you play softly or hard.

## Controls

- `Attack`: bipolar: right of centre adds snap, left of centre softens the pick.
- `Sustain`: bipolar: right of centre lengthens notes, left of centre tightens them.
- `Speed`: detector timing.
- `Focus`: sidechain highpass, so low-string thump drives the detector less.
- `Soft Clip`: blends in a soft clipper to tame boosted attacks.
- `Output`: +/-12 dB output trim.
- `Mix`: dry/wet blend.

## Factory presets

- `Pick Snap`: adds percussive attack for funk and country.
- `Violin Soft`: removes the pick attack for bowed, swelling notes.
- `Room Bloom`: boosts sustain for an ambient, compressed bloom.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-attack-sculpt-lv2
cmake --build build --target rtal-attack-sculpt-standalone
cmake --build build --target rtal-attack-sculpt-vst2
cmake --build build --target rtal-attack-sculpt-package
```
