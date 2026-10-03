# rtal-air-lift

`rtal-air-lift` is a harmonic exciter: it generates fresh upper harmonics for air and saturated low harmonics for body, rather than just boosting EQ.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The band above `Air Freq` is split off, saturated to create new harmonics, highpassed again so nothing muddy is added underneath, and mixed back in. The low band below `Body Freq` gets the same treatment for weight and warmth. `Odd-Even` blends a symmetric clipper (odd harmonics, edgy) with a biased one (even harmonics, warm).

## Controls

- `Air Freq`: start of the excited top band, 1.5 kHz to 9 kHz.
- `Air`: amount of generated top harmonics.
- `Harmonics`: saturation drive.
- `Odd-Even`: odd (edgy) to even (warm) harmonic balance.
- `Body Freq`: top of the excited low band, 60 Hz to 240 Hz.
- `Body`: amount of generated low harmonics.
- `Output`: +/-9 dB output trim.

## Factory presets

- `Acoustic Sparkle`: airy, warm top for acoustic guitars.
- `Dull Pickup Rescue`: stronger excitation for dark pickups or old strings.
- `Fat Bottom`: weighty low-end harmonics.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-air-lift-lv2
cmake --build build --target rtal-air-lift-standalone
cmake --build build --target rtal-air-lift-vst2
cmake --build build --target rtal-air-lift-package
```
