# rtal-crybaby-ghost

`rtal-crybaby-ghost` is a wah pedal with an automatable treadle position plus LFO and envelope 'ghost foot' modes, in three voicings.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The `Pedal` control is the treadle: map it to an expression pedal or automate it in your host. The envelope and LFO push the effective position from there, so you can rock the pedal by foot, let your picking do it, or let an LFO do it. Cry is a classic inductor-wah biquad, Four-Pole is a 4-pole Moog-style sweep, and Vocal is a narrow, throaty bandpass. Levels are matched across voicings.

## Controls

- `Voicing`: Cry, Four-Pole or Vocal.
- `Pedal`: treadle position (map to an expression pedal).
- `Envelope`: how far picking dynamics push the treadle.
- `LFO Depth`: automatic rocking depth.
- `LFO Rate`: automatic rocking speed.
- `Range`: sweep width around the treadle centre.
- `Boost`: output level.
- `Mix`: dry/wet blend.

## Factory presets

- `Shaft Groove`: envelope-driven cry wah for funk rhythm.
- `Slow Ghost Foot`: LFO rocking the four-pole sweep.
- `Vocal Talker`: throaty vocal wah following your picking.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-crybaby-ghost-lv2
cmake --build build --target rtal-crybaby-ghost-standalone
cmake --build build --target rtal-crybaby-ghost-vst2
cmake --build build --target rtal-crybaby-ghost-package
```
