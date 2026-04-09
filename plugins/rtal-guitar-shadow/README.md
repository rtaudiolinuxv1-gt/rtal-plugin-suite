# rtal-guitar-shadow

rtal-guitar-shadow is a gesture-reactive guitar shadowing effect.
The core sound is a guitar-shadow texture: bends and vibrato widen and brighten the wet
image instead of just modulating a static chorus or delay.

Release `1.0.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`.
Original project source is licensed under `DOC-1.0`.


## Project layout

- `src/rtal_guitar_shadow.dsp`: production DSP for plugin and standalone export.
- `scripts/export.sh`: generates metadata and plugin targets with the local Faust toolchain.
- `scripts/install.sh`: installs the built LV2, VST2, and standalone targets into user directories.
- `scripts/package.sh`: assembles a redistributable Linux release tarball.
- `supercollider/GuitarShadowPrototype.scd`: reference sketch for behavior prototyping.
- `BINARY_LICENSE_NOTICE.txt`: notice describing how DOC-1.0 applies to released binaries.
- `THIRD_PARTY_NOTICES.md`: third-party licensing boundary and release notes.
- `dist/`: generated metadata and export artifacts.
- `release/`: packaged release bundles.

# Public controls

- Shadow          : overall intensity and voice contribution.
- Bloom           : sustain-driven bloom and resonant brightness.
- Bend Sensitivity: amount of motion extracted from bends and vibrato.
- Harmonic Spread : tight doubling versus wider spectral offsets.
- Decay           : tail persistence after note release.
- Width           : stereo orbit and spatial spread.
- Mix             : dry/wet blend.

The controls are MIDI-mapped to CC 20-26 in the DSP metadata. A `Factory Preset`
selector is embedded in the DSP:

- `0`: `Manual`
- `1`: `Ghost Doubler`
- `2`: `Bending Halo`
- `3`: `Broken Constellation`

## Build

Configure and build:

```bash
cmake -S . -B build
cmake --build build
```

Generate metadata only:

```bash
cmake --build build --target rtal-guitar-shadow-meta
```

Install to the current user:

```bash
cmake --build build --target rtal-guitar-shadow-lv2
cmake --build build --target rtal-guitar-shadow-standalone
cmake --build build --target rtal-guitar-shadow-vst2
```

Build individual targets:

```bash
cmake --build build --target rtal-guitar-shadow-install-user
```

Run the standalone:

```bash
./dist/standalone/rtal-guitar-shadow
```

The factory presets are built into the DSP itself, so the standalone and plugin
exports share the same preset selector without external preset files.

Create a release tarball:

```bash
cmake --build build --target rtal-guitar-shadow-package
```

## Notes

- The standalone target uses `faust2jack`.
- Factory presets are embedded in the DSP rather than managed as external Faust preset files.
- `scripts/export.sh` expects the VST2 SDK at `../vstsdk2.4` relative to this project by default. Override with `SDK=/path/to/sdk`.
- VST export requires `faust2faustvst`.
- `DOC-1.0` applies to the original project source, not to third-party libraries or externally licensed generated/runtime code.
- Binary releases should include `LICENSE`, `BINARY_LICENSE_NOTICE.txt`, and `THIRD_PARTY_NOTICES.md`.
