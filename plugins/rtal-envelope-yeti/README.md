# rtal-envelope-yeti

`rtal-envelope-yeti` is an envelope filter / auto-wah with state-variable bandpass, lowpass and highpass modes plus a Moog-style ladder, sweeping up or down with your picking.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A detector follows the input envelope with independent attack and decay times. The envelope sweeps the filter cutoff over up to five and a half octaves above the `Base` frequency, or the other way in `Down` mode. Bandpass output is normalised to unity peak so high resonance quacks without jumping in level.

## Controls

- `Filter`: Bandpass, Lowpass, Ladder (Moog-style 4-pole) or Highpass.
- `Direction`: Up opens the filter as you pick harder; Down closes it.
- `Sensitivity`: detector gain.
- `Range`: sweep width in octaves.
- `Base`: resting cutoff frequency.
- `Resonance`: filter Q.
- `Attack`: how quickly the filter responds to a pick.
- `Decay`: how slowly the filter falls back.
- `Mix`: dry/wet blend.

## Factory presets

- `Funk Quack`: fast bandpass quack for rhythm parts.
- `Ladder Burp`: synth-like ladder sweep.
- `Down Sweep Dub`: inverted lowpass sweep that blooms open as notes decay.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-envelope-yeti-lv2
cmake --build build --target rtal-envelope-yeti-standalone
cmake --build build --target rtal-envelope-yeti-vst2
cmake --build build --target rtal-envelope-yeti-package
```
