# rtal-auto-expression

`rtal-auto-expression` hears how you play and lets each technique drive an effect. It detects pick force, palm mutes, bends, vibrato, slides and sustain, and maps each one to wah, drive, delay, reverb, chorus, tightness, volume or brightness.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Gesture detection.** The engine (`rtal_expression.h`) segments notes at pick attacks and measures every gesture relative to the start of the current note:
- **Pick Force** is the attack level.
- **Palm Mute** combines how fast the note decays in its first quarter second with how dark it is.
- **Bend** is how far the pitch has been pushed above where the note started (up to a whole step).
- **Vibrato** is the depth of pitch wobble, counted only when it turns around 3-10 times a second, so a bend does not register.
- **Slide** is fast pitch travel beyond the bend range without a new pick.
- **Sustain** is how long the note has rung.

Pitch comes from a YIN estimator running on a 4x decimated copy of the signal. Pitch gestures need single notes; pick force and palm mute work on chords too.

**Modulation matrix.** Each gesture row picks a target and an amount (negative amounts work in reverse). A target's value is its base knob plus every gesture routed to it, clamped to 0..1.

**Effect chain.** Tightness (low cut plus downward expander) > Drive (anti-aliased) > Wah > Brightness > Chorus > Delay > Reverb > Volume.

## Controls

- `Factory Preset`: Manual keeps every control live; the presets set the routing and the base settings.
- `Sensitivity`: How quiet a note can be and still be analysed.
- `Response`: Smoothing of the gesture controls.
- `<Gesture> Target / Amount`: For Pick Force, Palm Mute, Bend, Vibrato, Slide and Sustain: which effect parameter it moves and by how much (-1 to +1).
- `Heard meters`: Live value of each gesture.
- `Base Settings`: Resting value of each target: Wah, Drive, Delay, Reverb, Chorus, Tightness, Volume, Brightness.
- `Delay Time, Delay Feedback, Reverb Decay`: Fixed effect settings.
- `Output Level`: Final level.

## Factory presets

- `Manual`: Every control as set by hand (bends open the wah, palm mutes tighten, pick force drives, vibrato adds chorus, slides send to delay, sustain blooms the reverb).
- `Expressive Lead`: Pick force drives, bends brighten, vibrato chorus.
- `Metal Chug`: Palm mutes clamp the decay hard over a driven base.
- `Ambient Swells`: Hard picks duck the volume and sustained notes swell in, with reverb.
- `Funk Wah`: Pick force opens the wah, palm mutes tighten.
- `Blues Bender`: Bends add drive, vibrato sends to the delay.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-auto-expression-lv2
cmake --build build --target rtal-auto-expression-standalone
cmake --build build --target rtal-auto-expression-vst2
cmake --build build --target rtal-auto-expression-package
```
