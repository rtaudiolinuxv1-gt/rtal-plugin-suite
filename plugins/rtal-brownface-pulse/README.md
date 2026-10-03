# rtal-brownface-pulse

`rtal-brownface-pulse` is a tremolo with brownface-style harmonic, classic amplitude and stereo panning modes, a morphing LFO shape and a pick-reactive rate.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Harmonic mode splits the signal with a Linkwitz-Riley crossover and modulates lows and highs in opposite phase, as in early brown amps. That gives a phasey, swirling pulse rather than a plain volume chop. The LFO morphs from sine through triangle to a rounded square, and `Pick Push` speeds it up as you dig in.

## Controls

- `Mode`: Harmonic, Classic or Pan.
- `Rate`: LFO speed, 0.6 Hz to 15 Hz.
- `Depth`: modulation depth.
- `Shape`: sine, then triangle, then rounded square.
- `Split`: harmonic-mode crossover frequency.
- `Pick Push`: how much picking intensity speeds up the LFO.
- `Stereo Phase`: offsets the right channel's LFO.

## Factory presets

- `Brownface Harmonic`: classic harmonic tremolo.
- `Surf Chop`: fast, choppy, square-ish amplitude tremolo.
- `Slow Pan Dream`: slow, deep stereo pan.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-brownface-pulse-lv2
cmake --build build --target rtal-brownface-pulse-standalone
cmake --build build --target rtal-brownface-pulse-vst2
cmake --build build --target rtal-brownface-pulse-package
```
