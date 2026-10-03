# rtal-photocell-vibe

`rtal-photocell-vibe` is a photocell vibe: four staggered phase stages driven by a lagging lamp, for that throbbing, lopsided chorus and vibrato.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The classic vibe circuit modulates four phase-shift stages with a lamp shining on photocells. Here each stage has its own deliberately mismatched centre frequency, so the notches are unevenly spaced. The lamp brightens quickly and dims slowly, and the photocells respond to it nonlinearly. That asymmetry gives the characteristic throb instead of a smooth phaser sweep. Chorus mode mixes in the dry signal; Vibrato mode is the shifted signal alone, for pitch wobble.

## Controls

- `Mode`: Chorus or Vibrato.
- `Speed`: lamp LFO speed, 0.6 Hz to 12 Hz.
- `Intensity`: modulation depth.
- `Lamp Lag`: how slowly the lamp dims; higher throbs harder.
- `Preamp`: preamp saturation.
- `Volume`: output level.

## Factory presets

- `Machine Gun Throb`: deep, throbbing chorus.
- `Slow Swirl`: slow, smooth swirl.
- `Seasick Vibrato`: vibrato mode pitch wobble.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-photocell-vibe-lv2
cmake --build build --target rtal-photocell-vibe-standalone
cmake --build build --target rtal-photocell-vibe-vst2
cmake --build build --target rtal-photocell-vibe-package
```
