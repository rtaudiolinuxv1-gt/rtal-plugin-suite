# rtal-hum-killer

`rtal-hum-killer` removes mains hum and hiss: it notches 50/60 Hz and its harmonics, and adds a dynamic hiss filter for the quiet bits.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A chain of narrow notch filters sits on the mains frequency and up to seven of its harmonics, notching 60/120/180 Hz by 30 to 45 dB while leaving a low E at 82 Hz untouched. `Notch Depth` blends the notched signal with the original. A level detector also closes a gentle lowpass when you stop playing, so single-coil hiss disappears between phrases without dulling your notes.

## Controls

- `Mains`: 50 Hz or 60 Hz.
- `Harmonics`: number of notched harmonics, 1 to 8.
- `Notch Width`: notch bandwidth.
- `Notch Depth`: notched versus original blend.
- `Hiss Filter`: how far the top end closes when you are quiet.
- `Hiss Threshold`: level below which the hiss filter closes.

## Factory presets

- `Single Coil 60`: 60 Hz mains, five harmonics.
- `Single Coil 50`: 50 Hz mains, five harmonics.
- `Noisy Room`: all eight harmonics and a stronger hiss filter.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-hum-killer-lv2
cmake --build build --target rtal-hum-killer-standalone
cmake --build build --target rtal-hum-killer-vst2
cmake --build build --target rtal-hum-killer-package
```
