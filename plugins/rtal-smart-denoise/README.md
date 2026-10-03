# rtal-smart-denoise

`rtal-smart-denoise` learns your rig's hiss, hum and buzz by itself and removes them band by band, without chopping note tails.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Noise profile.** The engine (`rtal_smart_denoise.h`) uses 2048-point FFTs every 512 samples. The noise profile (smoothed power per frequency bin) is learned only in real gaps in the playing: frames whose overall level is within about 5 dB of the quietest frame of the last five seconds and at least 25 dB below the loudest, sustained for 0.15 s. Steady hiss, hum and buzz are present in every gap, so they are learned. Ringing or decaying notes never are: while you play, the profile can only drift down. Nothing is removed until the first gap has been heard. `Learn Now` averages whatever is playing (hold it while the strings are muted) and `Hold Profile` freezes the profile.

**Cleaning.** A Wiener filter driven by a decision-directed a-priori SNR (Ephraim-Malah) avoids the warbling "musical noise" of plain spectral subtraction. Gains are smoothed across neighbouring bins and never fall below the Reduction limit. They recover instantly but release slowly, so a note decaying into the noise fades naturally instead of being cut off.

**Measured results.** In tests with hiss plus 60 Hz hum, the noise in gaps drops by the Reduction setting, notes and tails come through within about 0.2 dB of the clean signal, and continuous playing with no gaps is passed unchanged.

The output is delayed by the analysis window (about 43 ms at 48 kHz); the dry path is delayed to match.

## Controls

- `Factory Preset`: Manual keeps every control live.
- `Learning`: Automatic (learns in every gap) or Hold Profile (freeze the learned noise).
- `Learn Now`: Hold while not playing to teach the noise directly.
- `Forget Profile`: Start learning from scratch.
- `Noise Floor / Learning Activity`: Meters for the learned floor and whether it is learning.
- `Reduction`: Maximum attenuation of noise-only bands.
- `Sensitivity`: Over-subtraction: how firmly bands near the noise floor are treated as noise.
- `Tail Release`: How slowly gains close after a note: longer protects tails, shorter cleans gaps faster.
- `Smoothing`: Smoothing of gains across frequency (less warble).
- `Removing`: Meter of the current reduction.
- `Listen to Removed Noise`: Hear only what is being taken away.
- `Mix / Level`: Blend with the (latency-matched) dry signal and output level.

## Factory presets

- `Manual`: Every control as set by hand.
- `Studio Transparent`: 12 dB of gentle cleaning with long tail protection.
- `Gentle Hiss`: Light hiss removal.
- `Heavy Clean-up`: 35 dB, firm and fast, for very noisy rigs.
- `Live Stage`: 20 dB with quick adaptation.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-smart-denoise-lv2
cmake --build build --target rtal-smart-denoise-standalone
cmake --build build --target rtal-smart-denoise-vst2
cmake --build build --target rtal-smart-denoise-package
```
