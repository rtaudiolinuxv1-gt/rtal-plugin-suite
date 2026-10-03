# rtal-fet-grab

`rtal-fet-grab` is a FET-style peak compressor with ultra-fast attack, ratio buttons including all-buttons-in, and gain-dependent colour.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

As on the classic hardware, the threshold is fixed: you drive `Input` into it and set `Output` to taste. Attack ranges from 20 microseconds to under a millisecond. All-buttons mode uses a near-limiting ratio, a harder knee and a lurching two-stage release for the aggressive 'nuke' sound. `Color` adds second-harmonic FET distortion that grows with gain reduction.

## Controls

- `Input`: drive into the fixed threshold, 0 dB to +40 dB.
- `Output`: output gain.
- `Ratio`: 4:1, 8:1, 12:1, 20:1 or All Buttons.
- `Attack`: 20 us to 0.8 ms.
- `Release`: 50 ms to 1.1 s.
- `Color`: gain-dependent FET harmonic distortion.
- `Mix`: parallel blend with the dry signal.
- `Gain Reduction`: meter in dB.

## Factory presets

- `Lead Grab`: 8:1 sustain and bite for leads.
- `All Buttons Smash`: all-buttons-in pumping.
- `Parallel Snap`: fast 20:1 compression blended under the dry signal.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-fet-grab-lv2
cmake --build build --target rtal-fet-grab-standalone
cmake --build build --target rtal-fet-grab-vst2
cmake --build build --target rtal-fet-grab-package
```
