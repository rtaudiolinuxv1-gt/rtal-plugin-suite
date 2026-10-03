# rtal-human-tune

`rtal-human-tune` is dynamic pitch correction that keeps the player human. It improves intonation while keeping natural imperfection, a tuning standard that floats around A440 without ever settling on it, vibrato and expressive scoops. A Perfect 440 mode gives exact, by-the-grid correction.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Detection.** Pitch is measured with the per-cycle period method from rtal-needle-tuner: a coarse zero-crossing estimate selects a lowpass that isolates the fundamental, then every cycle is timed between sub-sample-interpolated zero crossings. On pure tones this reads within about 0.1 cent. Smoothing works on the small deviation from an integer note anchor, so float32 rounding cannot freeze the reading cents off target.

**Target.** The played note's centre (smoothed by `Vibrato Keep`, so vibrato rides through untouched) is snapped to the nearest note of the chosen key and scale with a single table read. A 6-cent hysteresis margin stops a note wavering on a boundary from flipping. The correction is applied by a low-latency pitch shifter, faded in after each pick (`Attack Freedom`) and smoothed by `Retune Speed`.

**Human mode.** Three layers of imperfection are added to the target:
- The reference itself wanders a few cents around A440, as a slow random glide plus a slow sine from a random starting phase. It hovers around the line and never sits on it.
- Every new note gets its own random intonation offset (`Note Humanize`).
- A gentle micro drift adds life within each note.

**Never the same twice.** The randomness is not precomputed and is not Faust's fixed-seed noise. Every random stream is seeded from operating-system entropy (`std::random_device`, mixed with a high-resolution clock, a counter and an ASLR stack address) each time the host initialises the plugin instance. The streams are also continuously stirred by the low bits of the incoming audio, whose analog noise never repeats. Two activations, or two instances, never produce the same variations.

**Perfect 440 mode.** All humanisation is switched off and the correction strength is forced to 100%, so notes land on the exact grid (A = `Reference A`, 440 Hz by default). In offline tests, tones 24 to 46 cents off pitch were corrected to within about half a cent.

## Controls

- `Mode`: Human (natural, never-repeating imperfection) or Perfect 440 (exact).
- `Key / Scale`: target notes: Chromatic, Major, Natural Minor, Minor/Major Pentatonic, Blues, Dorian or Mixolydian.
- `Reference A`: tuning reference, 430 Hz to 450 Hz (440 by default). Human mode wanders around it.
- `Strength`: how much of the correction is applied in Human mode (Perfect mode always applies all of it).
- `Retune Speed`: 0 ms is an instant hard snap; higher values glide naturally.
- `Vibrato Keep`: how slowly the correction follows the note's centre; higher preserves wider, slower vibrato.
- `Attack Freedom`: time after each pick before correction fully engages, keeping natural scoops.
- `Note Humanize`: random intonation offset per note, up to +/-25 cents.
- `Reference Wander`: how far the floating tuning standard drifts from the reference.
- `Wander Rate`: how quickly the reference drifts.
- `Micro Drift`: small random pitch life within each note.
- `Tolerance`: notes already within this many cents are left alone.
- `Mix`: dry/wet blend.
- `Played Offset / Correction / Live Reference A`: meters showing how far you played from the grid, how much is being corrected, and the current floating reference.

## Factory presets

- `Session Player`: subtle correction with gentle human variation.
- `Live and Loose`: light-touch correction with more personality.
- `Studio Perfect`: Perfect 440 with natural retune speed.
- `Robot Hard Snap`: instant Perfect 440 snap with vibrato flattened, the hard robotic effect.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-human-tune-lv2
cmake --build build --target rtal-human-tune-standalone
cmake --build build --target rtal-human-tune-vst2
cmake --build build --target rtal-human-tune-package
```
