# rtal-coral-buzz

`rtal-coral-buzz` is an electric sitar: a buzzing bridge whose bright jawari sweep climbs through the harmonics as each note decays.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The string grazes a virtual curved bridge, a one-sided soft barrier that adds the characteristic buzz. A pitch tracker then centres a resonant band on the played note's harmonics: at the pick it sits around the 3rd harmonic and, as the note decays, it climbs past the 12th. That rising sweep (jawari) is what makes a sitar sound like a sitar. A sustain stage keeps the buzz alive, and an optional comb at the played pitch adds a sympathetic halo.

## Controls

- `Buzz`: bridge buzz amount.
- `Jawari`: strength and sharpness of the sweeping harmonic band.
- `Sweep Time`: how quickly the jawari band climbs.
- `Sustain`: evens out the decay so the buzz keeps going.
- `Drone Ring`: sympathetic comb halo at the played pitch.
- `Tone`: output brightness.
- `Mix`: dry/wet blend.

## Factory presets

- `Sixties Sitar`: classic electric sitar.
- `Raga Drone`: long, slow jawari sweep with strong drone ring.
- `Buzz Lead`: fast, buzzy lead tone.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-coral-buzz-lv2
cmake --build build --target rtal-coral-buzz-standalone
cmake --build build --target rtal-coral-buzz-vst2
cmake --build build --target rtal-coral-buzz-package
```
