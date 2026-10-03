# rtal-vowel-mouth

`rtal-vowel-mouth` is a talkbox-style formant filter that morphs through U-O-A-E-I from a knob, an LFO or your picking envelope.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Three resonant formant filters follow male-voice formant tables, interpolated continuously between vowels. The vowel position is the sum of the knob, an LFO and the input envelope, so each picked note can say 'wow' or 'yeah'. A drive stage adds harmonics for the formants to shape. Filter gains are normalised to unity peak.

## Controls

- `Vowel`: base vowel position, from U through O, A, E to I.
- `Talk`: how far each picked note pushes the vowel.
- `LFO Rate`: vowel LFO speed.
- `LFO Depth`: vowel LFO amount.
- `Throat`: formant scaling; low is a bigger, darker throat, high is smaller and brighter.
- `Resonance`: formant sharpness.
- `Drive`: pre-filter saturation.
- `Mix`: dry/wet blend.

## Factory presets

- `Talk Box`: envelope-driven talking lead.
- `Choir Robot`: slow LFO vowel sweep.
- `Yeah Yeah`: full-range envelope talk on every note.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-vowel-mouth-lv2
cmake --build build --target rtal-vowel-mouth-standalone
cmake --build build --target rtal-vowel-mouth-vst2
cmake --build build --target rtal-vowel-mouth-package
```
