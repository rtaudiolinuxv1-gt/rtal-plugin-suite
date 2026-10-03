# rtal-glass-squeeze

`rtal-glass-squeeze` is a guitar compressor with optical-style program-dependent release, a soft knee, sidechain highpass, parallel blend and 2 ms lookahead.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A stereo-linked peak detector feeds a soft-knee gain computer. Gain reduction is smoothed in the dB domain, and the release slows down the deeper the compressor has been working, like the memory of an optical cell. A 2 ms lookahead delays the audio so gain reduction is already in place when a pick attack arrives, avoiding overshoot. Makeup gain tracks threshold and ratio automatically.

## Controls

- `Squeeze`: threshold, 0 dB to -42 dB, with automatic makeup gain.
- `Ratio`: 1.5:1 to 18:1.
- `Attack`: 0.3 ms to 50 ms.
- `Release`: base release time, 40 ms to 1.2 s, lengthened by optical memory.
- `Sidechain HPF`: keeps low strings from pumping the compressor.
- `Blend`: parallel compression; dry is mixed back in below 1.
- `Output`: +/-12 dB output trim.
- `Gain Reduction`: meter in dB.

## Factory presets

- `Country Squash`: fast, snappy chicken-pickin' compression.
- `Studio Glue`: gentle, transparent levelling.
- `Infinite Sustain`: heavy compression for long sustaining leads.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-glass-squeeze-lv2
cmake --build build --target rtal-glass-squeeze-standalone
cmake --build build --target rtal-glass-squeeze-vst2
cmake --build build --target rtal-glass-squeeze-package
```
