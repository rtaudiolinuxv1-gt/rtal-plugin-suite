# rtal-silence-keeper

`rtal-silence-keeper` is a high-gain noise gate with hysteresis, hold, 1.5 ms lookahead, sidechain filtering and an adjustable range.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A filtered sidechain drives a gate state machine: it opens above the threshold and only closes after the level has dropped below threshold minus hysteresis and stayed there for the hold time, so decaying notes don't chatter. Attack and release are smoothed in the gain domain, and a short lookahead lets the gate open before a pick attack arrives. `Range` sets how far the gate closes, from full mute to gentle downward expansion.

## Controls

- `Threshold`: open threshold, -90 dB to -10 dB.
- `Hysteresis`: extra drop below threshold required to close.
- `Attack`: opening time.
- `Hold`: minimum open time after the signal drops.
- `Release`: closing time.
- `Range`: attenuation when closed, -80 dB (mute) to 0 dB.
- `Sidechain Focus`: sidechain band-limiting; focuses the detector on the guitar's mids.
- `Gate Open`: gate state meter.

## Factory presets

- `Tight Chug`: fast, tight gate for high-gain palm mutes.
- `Gentle Hum Cut`: slow, partial gate that lowers hum between phrases.
- `Staccato Chop`: hard, instant gate for stop-start riffs.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-silence-keeper-lv2
cmake --build build --target rtal-silence-keeper-standalone
cmake --build build --target rtal-silence-keeper-vst2
cmake --build build --target rtal-silence-keeper-package
```
