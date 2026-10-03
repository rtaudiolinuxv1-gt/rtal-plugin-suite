# rtal-hush-band

`rtal-hush-band` is a three-band downward expander: it quietly pushes down hiss and hum in each band without chopping your notes the way a gate does.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The guitar is split into low, mid and high bands with Linkwitz-Riley crossovers at 250 Hz and 3 kHz. In each band, whenever the level falls below the threshold, the band is turned down by `Ratio` dB per dB, never further than `Range`. Because each band acts separately, hiss in the top band is lowered while a sustaining low note keeps ringing. Separate focus offsets raise the threshold for the hiss and hum bands.

## Controls

- `Threshold`: level below which expansion starts.
- `Ratio`: expansion slope.
- `Range`: maximum reduction.
- `Release`: how quickly a band turns down after the level drops.
- `Hiss Focus`: extra threshold for the high band.
- `Hum Focus`: extra threshold for the low band; fully down leaves the lows alone.

## Factory presets

- `High Gain Hush`: strong, fast expansion for high-gain rigs.
- `Gentle Clean Up`: light, slow expansion.
- `Hiss Only`: works on the mids and highs only.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-hush-band-lv2
cmake --build build --target rtal-hush-band-standalone
cmake --build build --target rtal-hush-band-vst2
cmake --build build --target rtal-hush-band-package
```
