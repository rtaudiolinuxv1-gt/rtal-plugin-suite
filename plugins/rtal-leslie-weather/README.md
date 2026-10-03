# rtal-leslie-weather

`rtal-leslie-weather` is a rotary speaker simulation with a separately spinning horn and drum, realistic acceleration, Doppler shift, tube drive and stereo microphones.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A tube-style preamp feeds an 800 Hz Linkwitz-Riley crossover. The horn and the drum each have their own rotor with their own inertia: the horn spins up in about half a second while the heavy drum takes several seconds, which gives the classic smear when switching speeds. Each rotor produces Doppler pitch shift, amplitude modulation and directional darkening as seen from two microphones.

## Controls

- `Speed`: Brake, Chorale (slow) or Tremolo (fast).
- `Ramp`: rotor inertia; higher means slower speed changes.
- `Horn Balance`: horn versus drum level.
- `Doppler`: pitch modulation depth.
- `Drive`: preamp overdrive.
- `Mic Spread`: angle between the two microphones.
- `Mix`: dry/wet blend.

## Factory presets

- `Sunday Chorale`: slow, clean and wide.
- `Whirlwind`: fast rotor with deep Doppler.
- `Cracked Cabinet`: overdriven fast rotor.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-leslie-weather-lv2
cmake --build build --target rtal-leslie-weather-standalone
cmake --build build --target rtal-leslie-weather-vst2
cmake --build build --target rtal-leslie-weather-package
```
