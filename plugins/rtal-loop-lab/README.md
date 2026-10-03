# rtal-loop-lab

`rtal-loop-lab` is a stereo looper with record, overdub with fading layers, play/stop, clear, half-speed and reverse playback.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The first recording sets the loop length (up to about 21 s at 48 kHz, or 10 s at 96 kHz). Recording again while the loop plays overdubs on top, and `Overdub Feedback` below 1 fades older layers each pass, for evolving, self-erasing loops. Playback can run at normal or half speed, forwards or reversed (overdubbing works at normal speed in either direction). `Clear` wipes the loop so the next recording starts fresh.

## Controls

- `Record - Overdub`: first press records the loop; later presses overdub.
- `Play`: play/stop the loop.
- `Clear`: erase the loop.
- `Speed`: Normal, Half, Reverse or Half Reverse.
- `Overdub Feedback`: how much of the existing loop survives each overdub pass.
- `Loop Level`: loop playback level.
- `Loop Tone`: loop playback brightness.
- `Dry`: dry level.
- `Loop Length`: meter in seconds.

## Factory presets

- `Classic Looper`: straight looping.
- `Fading Layers`: each overdub pass fades older layers.
- `Ambient Half-Speed`: dark, half-speed playback for ambient beds.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-loop-lab-lv2
cmake --build build --target rtal-loop-lab-standalone
cmake --build build --target rtal-loop-lab-vst2
cmake --build build --target rtal-loop-lab-package
```
