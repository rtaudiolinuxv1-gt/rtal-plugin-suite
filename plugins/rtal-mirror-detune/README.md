# rtal-mirror-detune

`rtal-mirror-detune` is a studio micro-pitch doubler: mirrored detune and short delays for instant width, with the low end kept mono.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Two granular pitch shifters detune copies of the input up and down by the same amount (up to +/-30 cents), each with its own short delay, the classic rack micro-pitch trick for widening a part. Slow random drift keeps it from sounding static. A Linkwitz-Riley highpass on the doubled sides keeps everything below the `Low Mono` crossover centred and mono compatible.

## Controls

- `Detune`: mirrored pitch offset, up to +/-30 cents.
- `Delay`: side delays, 2 ms to 30 ms.
- `Drift`: slow random pitch movement.
- `Feedback`: recirculates the shifted copies for a cascading shimmer.
- `Low Mono`: crossover below which the doubles are removed.
- `Tone`: brightness of the doubles.
- `Mix`: doubler level.

## Factory presets

- `Studio Wide`: subtle, natural-sounding widening.
- `Eighties Rack`: classic detuned rack sound with a little feedback.
- `Seasick Double`: wide detune with heavy drift.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-mirror-detune-lv2
cmake --build build --target rtal-mirror-detune-standalone
cmake --build build --target rtal-mirror-detune-vst2
cmake --build build --target rtal-mirror-detune-package
```
