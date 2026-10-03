# rtal-pixel-rot

`rtal-pixel-rot` is a bit crusher and sample-rate reducer with clock jitter, glitch freezes and tone shaping.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A variable sample-and-hold clock runs from 400 Hz to 44.1 kHz with optional jitter, and a quantiser reduces resolution down to 1 bit, continuously, so bit depth can be swept. `Glitch` stops the clock at random moments, freezing a single sample into a buzz.

## Controls

- `Bits`: resolution from 16 bits down to 1 bit, continuously variable.
- `Rate`: sample-rate reduction.
- `Jitter`: random wobble of the sample clock.
- `Drive`: pre-crush gain and saturation.
- `Glitch`: probability of clock freezes.
- `Tone`: post-crush lowpass.
- `Mix`: dry/wet blend.

## Factory presets

- `Handheld Console`: 4-bit portable game console grit.
- `Dusty Sampler`: 12-bit vintage sampler warmth.
- `Broken Modem`: 3-bit jittery glitch noise.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-pixel-rot-lv2
cmake --build build --target rtal-pixel-rot-standalone
cmake --build build --target rtal-pixel-rot-vst2
cmake --build build --target rtal-pixel-rot-package
```
