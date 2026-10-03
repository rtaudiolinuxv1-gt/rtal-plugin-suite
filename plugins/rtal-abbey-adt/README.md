# rtal-abbey-adt

`rtal-abbey-adt` is artificial double tracking: a varispeed tape copy wanders behind your part, or swoops into tape flanging.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The 1960s studio trick: a second tape machine replays the part a few tens of milliseconds late while its speed is gently rocked, so the copy drifts in time and pitch like a second performance. `Double` mode keeps the copy 15 ms to 60 ms behind with random varispeed wander. `Tape Flange` mode brings the copy within a few milliseconds and sweeps it for the original tape-flanging swoosh. `Spread` places the original and the copy on opposite sides.

## Controls

- `Mode`: Double or Tape Flange.
- `Delay`: copy delay (15 ms to 60 ms for Double, around 1 ms to 4 ms for Flange).
- `Wander`: depth of the varispeed movement.
- `Wander Rate`: speed of the varispeed movement.
- `Tape Tone`: bandwidth of the copy.
- `Spread`: stereo separation of original and copy.
- `Mix`: copy level.

## Factory presets

- `Studio Two Double`: classic subtle double.
- `Lazy Double`: late, loose and wide double.
- `Tape Flange`: centred tape flanging.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-abbey-adt-lv2
cmake --build build --target rtal-abbey-adt-standalone
cmake --build build --target rtal-abbey-adt-vst2
cmake --build build --target rtal-abbey-adt-package
```
