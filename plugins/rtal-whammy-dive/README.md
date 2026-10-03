# rtal-whammy-dive

`rtal-whammy-dive` is an expression pitch shifter for whammy bends, dive bombs and harmonies, with a momentary kick switch.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

`Position` is the expression treadle: at 0 the pitch is unshifted, at 1 it reaches the chosen interval, and anything between bends smoothly. `Kick` jumps the treadle fully down, so you can trigger octave screams or dive bombs without an expression pedal, and `Ramp` sets how quickly the pitch travels. Downward intervals use longer grains so low notes stay smooth. Harmony mode keeps the dry signal alongside the shifted one.

## Controls

- `Interval`: +2 octaves, +1 octave, +5th, +4th, -2nd, -1 octave, -2 octaves, Dive Bomb (-3 octaves) or Detune.
- `Mode`: Whammy (shifted only) or Harmony (dry plus shifted).
- `Position`: expression treadle.
- `Kick`: momentary full-travel switch.
- `Ramp`: pitch travel time, 5 ms to 1.5 s.
- `Tone`: output brightness.
- `Level`: output level.

## Factory presets

- `Octave Scream`: fast octave-up bends.
- `Dive Bomb`: slow three-octave dive.
- `Shallow Chorus Bend`: subtle detune harmony.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-whammy-dive-lv2
cmake --build build --target rtal-whammy-dive-standalone
cmake --build build --target rtal-whammy-dive-vst2
cmake --build build --target rtal-whammy-dive-package
```
