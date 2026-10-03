# rtal-tri-chorus

`rtal-tri-chorus` is a three-voice bucket-brigade-style chorus and string ensemble with dual LFOs, a vibrato mode and stereo spread.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Three modulated delay voices sit 120 degrees apart on both a slow and a fast LFO, the classic string-ensemble topology. Each voice runs through a BBD-like bandwidth limit and a soft saturation. Voices are spread left, centre and right. `Ensemble` mode always adds the fast LFO for the lush string-machine shimmer, and `Vibrato` mode gives a single fully-wet voice for pure pitch wobble.

## Controls

- `Mode`: Chorus, Ensemble or Vibrato.
- `Rate`: slow LFO speed (and fast LFO, proportionally).
- `Depth`: slow modulation depth.
- `Shimmer`: fast LFO depth.
- `Delay`: base delay, 3 ms to 20 ms.
- `Tone`: BBD bandwidth.
- `Width`: stereo spread of the voices.
- `Mix`: dry/wet blend.

## Factory presets

- `Dimension Two`: subtle, wide studio chorus.
- `String Machine`: lush ensemble shimmer.
- `Seasick Vibrato`: deep, fully wet vibrato.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-tri-chorus-lv2
cmake --build build --target rtal-tri-chorus-standalone
cmake --build build --target rtal-tri-chorus-vst2
cmake --build build --target rtal-tri-chorus-package
```
