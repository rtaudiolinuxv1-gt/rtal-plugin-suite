# rtal-tone-carver

`rtal-tone-carver` is a guitar parametric EQ: low and high cuts, shelves and two sweepable mid bands, with guitar-tuned factory curves.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A 12 dB/oct low cut, a low shelf, two constant-Q peaking bands sweeping 150 Hz to 2 kHz and 800 Hz to 8 kHz, a high shelf and a 12 dB/oct high cut, in that order, followed by an output trim. The factory curves cover the common guitar moves: pushing the mids for a lead, scooping for metal, and carving a part to sit in a band mix.

## Controls

- `Low Cut`: 12 dB/oct highpass, 20 Hz to 400 Hz.
- `Low Shelf`: +/-15 dB.
- `Low Freq`: low shelf frequency.
- `Mid 1 Gain / Freq / Q`: first peaking band.
- `Mid 2 Gain / Freq / Q`: second peaking band.
- `High Shelf`: +/-15 dB.
- `High Freq`: high shelf frequency.
- `High Cut`: 12 dB/oct lowpass, 2 kHz to 20 kHz.
- `Output`: +/-18 dB.

## Factory presets

- `Mid Push Lead`: mid boost and trimmed lows/highs so a lead cuts through.
- `Metal Scoop`: scooped mids with tight lows and presence.
- `Mix Fit`: carves mud and boxiness so a guitar sits in a band.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-tone-carver-lv2
cmake --build build --target rtal-tone-carver-standalone
cmake --build build --target rtal-tone-carver-vst2
cmake --build build --target rtal-tone-carver-package
```
