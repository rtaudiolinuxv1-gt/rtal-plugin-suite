# rtal-digital-dust

`rtal-digital-dust` is a degrading digital delay: every repeat is re-crushed in bit depth and sample rate, so echoes crumble into bit dust.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The bit crusher, sample-rate reducer and tone filter sit inside the feedback loop, so each pass through the delay loses more resolution. The first echo is gently lo-fi and later echoes dissolve into grit. Clock jitter adds unstable, early-sampler character, and the right channel runs a slightly longer delay for width.

## Controls

- `Time`: delay time, 40 ms to 1.2 s.
- `Feedback`: number of repeats.
- `Crush`: bit depth reduction per pass, 14 bits down to 3 bits.
- `Decimate`: sample-rate reduction per pass.
- `Jitter`: clock instability.
- `Tone`: loop bandwidth.
- `Width`: stereo time offset and channel separation.
- `Mix`: dry/wet blend.

## Factory presets

- `Early Sampler Echo`: gentle 12-bit style echo.
- `Crumbling Repeats`: long feedback that disintegrates.
- `Glitch Cascade`: short, jittery, heavily crushed repeats.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-digital-dust-lv2
cmake --build build --target rtal-digital-dust-standalone
cmake --build build --target rtal-digital-dust-vst2
cmake --build build --target rtal-digital-dust-package
```
