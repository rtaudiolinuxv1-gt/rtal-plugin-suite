# rtal-firefly-taps

`rtal-firefly-taps` is an eight-tap scattered delay with rhythmic tap patterns, swelling or fading tap shapes and stereo spread.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Eight taps read one delay line at positions set by the chosen pattern as fractions of `Length`: evenly spaced, golden-ratio scattered, speeding up (accelerando), slowing down (ritardando), irregular, or bouncing-ball gaps that shrink toward the end. `Shape` fades the taps out, keeps them flat, or swells them in for a reverse-like build. Taps alternate across the stereo field, and the last tap can feed back to repeat the pattern.

## Controls

- `Pattern`: Even, Golden, Accelerando, Ritardando, Scatter or Bounce.
- `Length`: time to the last tap, 200 ms to 2.4 s.
- `Shape`: right of centre fades taps out, left of centre swells them in.
- `Feedback`: repeats the whole pattern.
- `Spread`: stereo spread of the taps.
- `Tone`: tap bandwidth.
- `Mix`: dry/wet blend.

## Factory presets

- `Bouncing Ball`: taps accelerate like a dropped ball.
- `Golden Scatter`: irregular golden-ratio shower of echoes.
- `Reverse Swell Taps`: slowing taps that swell toward the end.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-firefly-taps-lv2
cmake --build build --target rtal-firefly-taps-standalone
cmake --build build --target rtal-firefly-taps-vst2
cmake --build build --target rtal-firefly-taps-package
```
