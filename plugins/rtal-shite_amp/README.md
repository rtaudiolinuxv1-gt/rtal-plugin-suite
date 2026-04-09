# rtal-shite_amp

`rtal-shite_amp` is a deliberately bad amp voice: saggy, rattling, boxy, and broken in a useful way.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## Controls

- `Gain`: preamp abuse.
- `Sag`: supply collapse under playing dynamics.
- `Rattle`: speaker rattle modulation.
- `Tone`: dark-to-bright cabinet tilt.
- `Rot`: rot and low-end decay.
- `Level`: output level.
- `Mix`: dry/wet blend.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-shite_amp-lv2
cmake --build build --target rtal-shite_amp-standalone
cmake --build build --target rtal-shite_amp-vst2
cmake --build build --target rtal-shite_amp-package
```
