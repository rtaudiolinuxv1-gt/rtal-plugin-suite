# rtal-tape-ghost

`rtal-tape-ghost` is a three-head tape echo: repeats wobble with wow and flutter, saturate as they recirculate, and darken as the tape ages.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The guitar is summed to mono and written to a virtual tape loop read by three playback heads at 1/3, 2/3 and 1x the delay time. Transport speed is modulated by slow wow and fast flutter, the record path saturates through a tape-style soft clipper with a playback head bump around 120 Hz, and the feedback path loses top and bottom end as `Age` increases. Changing `Time` glides the transport like a real machine, so knob moves pitch-bend the repeats.

## Controls

- `Time`: longest head delay, 40 ms to 900 ms. Glides like a tape transport.
- `Heads`: 0 is head 3 only; turning up adds head 2 then head 1 for rhythmic multi-tap patterns.
- `Feedback`: repeats; saturation keeps high settings musical.
- `Wow`: slow pitch drift of the transport.
- `Flutter`: fast pitch shimmer of the transport.
- `Age`: tape saturation, darker repeats and a thinner low end.
- `Width`: pans heads 1 and 2 apart.
- `Mix`: dry/wet blend.

## Factory presets

- `Slapback Shed`: single short head for rockabilly slap.
- `Space Haunt`: all three heads with long, wide feedback.
- `Melted Reel`: worn-out tape with heavy wow and saturation.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-tape-ghost-lv2
cmake --build build --target rtal-tape-ghost-standalone
cmake --build build --target rtal-tape-ghost-vst2
cmake --build build --target rtal-tape-ghost-package
```
