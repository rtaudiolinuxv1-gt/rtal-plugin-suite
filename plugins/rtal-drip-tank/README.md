# rtal-drip-tank

`rtal-drip-tank` is a three-spring reverb tank with the dispersive chirp, dwell drive and surf drip of a classic amp spring reverb.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Each of three springs is a feedback delay loop containing a cascade of stretched allpass filters. The cascade delays high frequencies differently from low ones, which produces the characteristic descending chirp of a spring. Loop losses set decay time, and a saturating driver models the tank input transducer.

## Controls

- `Dwell`: drive into the tank; higher is more splashy and compressed.
- `Decay`: spring decay time.
- `Drip`: allpass dispersion amount, the chirp and drip.
- `Tension`: spring length.
- `Tone`: brightness of the tank.
- `Width`: stereo spread between springs.
- `Mix`: dry/wet blend.

## Factory presets

- `Blackface Tank`: classic amp reverb at a moderate setting.
- `Surf Drip`: dwell cranked for drippy surf lines.
- `Dub Plate`: long, dark, wide tank.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-drip-tank-lv2
cmake --build build --target rtal-drip-tank-standalone
cmake --build build --target rtal-drip-tank-vst2
cmake --build build --target rtal-drip-tank-package
```
