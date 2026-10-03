# rtal-dub-station

`rtal-dub-station` is a dub echo station built for live dubbing: a throw switch, sweepable loop filter, runaway feedback and a spring tank.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The echo loop contains a bipolar filter (lowpass closing to the left of centre, highpass opening to the right) with resonance, a tape-style wobble, and a saturator that lets `Feedback` go past unity into controlled self-oscillation for dub sirens. The `Throw` switch slams the send open so you can toss single chords into the echo. The echoes feed a small two-spring tank.

## Controls

- `Throw`: momentary send to the echo.
- `Time`: echo time, 60 ms to 1.2 s; changes glide like tape.
- `Feedback`: repeats, up to just past unity for runaway echoes.
- `Filter`: bipolar loop filter: left darkens, right thins.
- `Resonance`: loop filter resonance.
- `Send`: constant echo send level.
- `Spring`: spring tank level on the echoes.
- `Wobble`: tape-style time wobble.
- `Mix`: dry/wet blend.

## Factory presets

- `Skank Throw`: bright offbeat echoes ready for throws.
- `Siren Runaway`: feedback past unity for swelling self-oscillation.
- `Filter Melt`: dark, resonant, melting repeats.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-dub-station-lv2
cmake --build build --target rtal-dub-station-standalone
cmake --build build --target rtal-dub-station-vst2
cmake --build build --target rtal-dub-station-package
```
