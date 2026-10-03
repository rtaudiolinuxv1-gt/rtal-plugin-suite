# rtal-power-cut

`rtal-power-cut` is a tape stop and spin-up effect: flick the switch and the deck grinds to a halt; release it and the motor winds back up.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Switching `Stop` on ramps the virtual tape speed down to zero, reading the delay buffer at the decreasing speed so pitch, level and bandwidth all fall together as real tape playback does. Releasing the switch spins the motor back up from where it stopped, then crossfades back to the live signal and resets the tape position. Map `Stop` to a footswitch or automate it for rhythmic stops.

## Controls

- `Stop`: engage to stop the tape, release to restart.
- `Stop Time`: braking time, 50 ms to 4 s.
- `Start Time`: spin-up time, 30 ms to 2.5 s.
- `Curve`: braking shape; low brakes late and hard, high sags early.
- `Darken`: how strongly the bandwidth collapses with speed.
- `Mix`: dry/wet blend.

## Factory presets

- `Turntable Brake`: quick record-player stop.
- `Slow Death`: long, sagging power failure.
- `Quick Glitch`: very fast stop/start for stutters.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-power-cut-lv2
cmake --build build --target rtal-power-cut-standalone
cmake --build build --target rtal-power-cut-vst2
cmake --build build --target rtal-power-cut-package
```
