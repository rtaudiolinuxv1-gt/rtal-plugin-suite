# rtal-inverse-cathedral

`rtal-inverse-cathedral` is a reverse reverb: a big hall's tail is cut into windows and played backwards, so every phrase swells up out of nothing.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The guitar feeds a large hall, and the hall's tail feeds a reverse engine: two read heads sweep backwards through windows of the tail with complementary crossfades, as in rtal-backwards-sunday. Each reverb tail therefore plays from its quiet end to its loud end, giving the classic inhaling reverse-reverb swell. Some of the normal forward tail can be blended back in.

## Controls

- `Swell Length`: length of each reversed window, 0.25 s to 2 s.
- `Size`: hall decay.
- `Smoothness`: crossfade length between windows.
- `Forward Tail`: amount of normal (forward) reverb.
- `Tone`: brightness of the swell.
- `Mix`: dry/wet blend.

## Factory presets

- `Classic Reverse Verb`: the classic production reverse reverb.
- `Long Inhale`: long, slow swells.
- `Ghost Choir`: huge, smooth swells with some forward tail.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-inverse-cathedral-lv2
cmake --build build --target rtal-inverse-cathedral-standalone
cmake --build build --target rtal-inverse-cathedral-vst2
cmake --build build --target rtal-inverse-cathedral-package
```
