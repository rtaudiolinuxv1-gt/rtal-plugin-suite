# rtal-brickwall

`rtal-brickwall` is a lookahead brickwall limiter with drive, ceiling, adaptive release, stereo link, optional soft saturation and a final safety clip.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The required gain reduction is held for the 1.5 ms lookahead window and smoothed so the attack completes before the delayed audio arrives. Release is exponential and slows down the harder the limiter works, to avoid pumping. Stereo link sets how much one channel's peaks reduce the other. A final hard clip at the ceiling guarantees nothing overshoots.

## Controls

- `Drive`: input gain into the limiter, 0 dB to +24 dB.
- `Ceiling`: maximum output level, -12 dB to 0 dB.
- `Release`: base release time.
- `Stereo Link`: 0 limits each side independently, 1 fully linked.
- `Soft Saturation`: blends in a tanh stage before limiting for denser loudness.
- `Gain Reduction`: meter in dB.

## Factory presets

- `Transparent`: light peak control at -1 dB.
- `Loud Rhythm`: solid loudness for rhythm parts.
- `Squashed`: heavily driven and saturated.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-brickwall-lv2
cmake --build build --target rtal-brickwall-standalone
cmake --build build --target rtal-brickwall-vst2
cmake --build build --target rtal-brickwall-package
```
