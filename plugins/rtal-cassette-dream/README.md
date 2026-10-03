# rtal-cassette-dream

`rtal-cassette-dream` is a lo-fi cassette deck: wow, flutter, tape saturation, worn bandwidth, oxide dropouts, hiss and azimuth error.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The signal is saturated through an asymmetric tape-style clipper and then played back through a delay line whose speed wobbles with slow, lumpy wow and fast flutter. Worn heads limit the bandwidth and add a low-end head bump, and random oxide dropouts briefly duck and dull the sound. Optional filtered hiss sits on top. The right channel drifts slightly in time and treble, like a misaligned azimuth.

## Controls

- `Wow`: slow pitch drift.
- `Flutter`: fast pitch shimmer.
- `Saturation`: tape drive and compression.
- `Age`: bandwidth loss and head wear.
- `Dropouts`: frequency and depth of oxide dropouts.
- `Hiss`: tape hiss level.
- `Azimuth`: stereo time and treble mismatch.
- `Mix`: dry/wet blend.

## Factory presets

- `Pocket Walkman`: light, warm portable-deck wobble.
- `Fourth Generation Dub`: heavily saturated, darker copy-of-a-copy.
- `Attic Find`: seasick, worn-out tape with dropouts.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-cassette-dream-lv2
cmake --build build --target rtal-cassette-dream-standalone
cmake --build build --target rtal-cassette-dream-vst2
cmake --build build --target rtal-cassette-dream-package
```
