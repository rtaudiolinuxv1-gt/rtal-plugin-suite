# rtal-moon-ring

`rtal-moon-ring` is a ring modulator whose carrier can follow the pitch you play, so ring modulation stays musical, with fixed and LFO-swept modes too.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

In Tracked mode a pitch tracker sets the carrier to a multiple of the played note. Harmonic ratios (1, 2, 3) give bell-like and organ-like tones that stay in tune with every note, while 3/2, 5/2 and the golden ratio give increasingly clangorous sidebands. Fixed mode uses a set frequency for classic sci-fi and radio effects. A sweep LFO can move the carrier, and the right channel's carrier runs a quarter cycle ahead for stereo motion.

## Controls

- `Carrier`: Tracked (follows your pitch) or Fixed.
- `Ratio`: carrier multiple of the played note in Tracked mode.
- `Frequency`: carrier frequency in Fixed mode, 20 Hz to 3 kHz.
- `Shape`: sine to soft-square carrier.
- `Sweep Depth`: LFO carrier sweep, up to +/-2 octaves.
- `Sweep Rate`: sweep LFO speed.
- `Tone`: output lowpass.
- `Mix`: dry/wet blend.

## Factory presets

- `Harmonic Bell`: tracked octave carrier for in-tune bell tones.
- `Dalek Radio`: fixed square-ish carrier.
- `Orbit Sweep`: fixed carrier swept by a slow LFO.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-moon-ring-lv2
cmake --build build --target rtal-moon-ring-standalone
cmake --build build --target rtal-moon-ring-vst2
cmake --build build --target rtal-moon-ring-package
```
