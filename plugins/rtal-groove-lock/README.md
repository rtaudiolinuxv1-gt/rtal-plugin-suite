# rtal-groove-lock

`rtal-groove-lock` locks rhythmic effects to the tempo of your own playing, without a host clock. It listens to your picking, works out the tempo and the beat, and drives a sixteen-step gate, a tremolo, a filter sweep and a delay from it.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Onsets.** The tempo tracker (`rtal_tempo.h`) splits the guitar into four bands and sums each band's log-energy rise per 256-sample frame, giving an onset-strength curve that spikes on every pick or strum.

**Tempo.** Every quarter second, the autocorrelation of the last six seconds of that curve is scored with a comb (one to four beats plus half beats) across the allowed range. A gentle prior around 110 BPM keeps octave errors rare, and a new tempo must win three times running before it replaces the current one.

**Beat.** The recent onsets are matched against a pulse train at the current tempo, and the best alignment pulls a free-running beat clock into place, like a phase-locked loop. A continuity prior keeps it from flipping to the off-beat, and corrections only speed up or slow down the clock (at most 40%), so steps never re-fire.

**Bar.** Accented beats choose the downbeat of a 4/4 bar; a change must win clearly for two seconds.

When you stop, the clock keeps running at the last tempo. `Slowest/Fastest Tempo` resolves half-time or double-time ambiguity, and `Hold Tempo` freezes the tempo while still following the beat.

## Controls

- `Factory Preset`: Manual keeps every control live.
- `Tempo Source`: Follow Playing, Hold Tempo (keep the tempo, still follow the beat) or Manual.
- `Manual Tempo`: Tempo used in Manual mode.
- `Slowest / Fastest Tempo`: Range the tracker may choose from.
- `Sensitivity`: How quiet a pick can be and still count.
- `Tempo, Beat, Lock`: Meters: detected BPM, beat of the bar, and lock confidence.
- `Gate: Depth, Pattern, Swing, Smoothing`: Sixteen-step rhythmic gate with eight patterns.
- `Tremolo: Depth, Rate, Shape, Stereo Offset`: Tempo-synced tremolo from a smooth sine to a hard chop.
- `Filter: Depth, Rate, Low, High, Resonance`: Resonant low-pass swept in time.
- `Delay: Mix, Time, Feedback, Tone, Ping Pong`: Tempo-synced delay; the time glides when the tempo changes.
- `Level`: Output level.

## Factory presets

- `Manual`: Every control as set by hand.
- `Pulse Tremolo`: Smooth eighth-note tremolo.
- `Trance Gate`: Sixteenth gate with a ping-pong eighth delay.
- `Dotted Eighth Echo`: Dotted-eighth delay locked to your tempo.
- `Funk Filter`: Eighth-note resonant filter sweep with a light swing.
- `Everything Locked`: Broken-sixteenth gate, sixteenth tremolo, filter and ping-pong delay together.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-groove-lock-lv2
cmake --build build --target rtal-groove-lock-standalone
cmake --build build --target rtal-groove-lock-vst2
cmake --build build --target rtal-groove-lock-package
```
