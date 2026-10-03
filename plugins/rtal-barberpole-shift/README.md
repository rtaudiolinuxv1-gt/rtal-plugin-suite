# rtal-barberpole-shift

`rtal-barberpole-shift` is a Bode-style frequency shifter with a delayed feedback loop: each repeat moves further up or down the spectrum, creating endless barberpole spirals.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A pair of 90-degree allpass networks builds an analytic signal, which is single-sideband modulated by a quadrature oscillator. Unlike pitch shifting, every partial moves by the same number of hertz, so small shifts give phasing and chorus-like beating while large shifts turn chords into bells and clangs. The feedback loop runs through a delay, tone filter and soft limiter, so each echo is shifted again.

## Controls

- `Shift`: center is no shift; either side sweeps exponentially up to +/-1200 Hz (left shifts down, right shifts up).
- `Fine`: +/-3 Hz trim for slow phasing effects.
- `Feedback`: how many times the signal re-enters the shifter.
- `Delay`: feedback delay, 2 ms to 600 ms.
- `Tone`: feedback loop bandwidth.
- `Spread`: moves the right channel toward the mirrored shift direction; at full, left climbs while right falls.
- `Mix`: dry/wet blend.

## Factory presets

- `Endless Stair`: rising barberpole echoes.
- `Sideband Chorus`: tiny mirrored shifts for a wide, beating chorus.
- `Broken Radio`: large shift with dark, ringing feedback.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-barberpole-shift-lv2
cmake --build build --target rtal-barberpole-shift-standalone
cmake --build build --target rtal-barberpole-shift-vst2
cmake --build build --target rtal-barberpole-shift-package
```
