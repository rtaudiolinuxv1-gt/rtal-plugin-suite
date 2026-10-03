# rtal-phase-mod

`rtal-phase-mod` is FM guitar: audio-rate phase modulation locked to your pitch, for DX-style electric pianos, brass and metallic clangs.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A sine modulator runs at a ratio of the tracked pitch and swings a short delay line at audio rate, which phase-modulates the guitar itself. The swing is scaled so the modulation index is exactly the requested number of radians at any pitch. Integer ratios give harmonic sidebands (electric piano, brass), while ratios like 1.41 or 3.5 give inharmonic bells and clangs. The index follows an envelope fired on each pick and can track playing dynamics, like an FM operator envelope.

## Controls

- `Ratio`: modulator frequency as a multiple of your pitch: 0.5, 1, 2, 3, 3.5, 1.41 or 7.
- `Index`: modulation depth (brightness).
- `Dynamics`: how much picking strength raises the index.
- `Index Decay`: how quickly the brightness decays after each pick.
- `Tone`: output lowpass.
- `Mix`: dry/wet blend.

## Factory presets

- `Electric Piano`: harmonic, decaying FM for keys-like tones.
- `Brassy Growl`: sustained harmonic brass.
- `Inharmonic Clang`: 1.41 ratio for bells and metal.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-phase-mod-lv2
cmake --build build --target rtal-phase-mod-standalone
cmake --build build --target rtal-phase-mod-vst2
cmake --build build --target rtal-phase-mod-package
```
