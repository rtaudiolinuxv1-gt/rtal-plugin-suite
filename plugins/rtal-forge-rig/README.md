# rtal-forge-rig

`rtal-forge-rig` is a complete guitar rig in one plugin. It has twelve effects that can be chained in any order, one amp built from ten preamp models and ten power-amp models, six cabinets plus a direct option, and two virtual microphones that can be placed anywhere on the speaker. All amp and cabinet names are original; the models are voiced after familiar amp families, and no trademarked names are used.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Chain.** There are twelve chain slots, and each slot can run any of the twelve effects. The signal passes through the slots in order, and the amp goes in after the slot set by `Amp After Slot`. The default is 12, which places every effect before the amp. Lower values move the effects in the later slots after the amp, the usual place for delay and reverb. Each effect is a single instance: if two slots pick the same effect, only the first is used and the later slot passes the signal straight through. Each link in the chain adds one sample of latency. The routing is computed once per audio block by a small C++ helper (`rtal_router.h`), so changing the order is click-safe and costs nothing per sample.

**Effects.** Echo (tape-style, with wow and darkening repeats), Delay (clean digital), Ping Pong (repeats bounce left and right), Chorus (two voices), Compressor, Auto-Wah (envelope-swept resonant filter), Phaser (six stages with feedback), Flanger (with feedback and manual sweep), Tremolo (with shape and stereo pan), Reverb (an original feedback delay network), Noise Cancel (an expander-style gate with a hum notch) and Fuzz Box (with octave-up).

**Preamp.** There are ten models: Glass Tube Pre, Plex Lead 59, Rectangle Triple, Vex Top-30, Citrus Rocker, Furnace 50-50, Nu Rage, Blueline Deluxe, Dark Star 100 and Boulevard Blues. Each is a two- or three-stage triode-style circuit with its own bias, interstage filtering, bright cap and built-in mid voicing. The clipping is anti-aliased (ADAA tanh), followed by a Bass, Middle and Treble tone stack. The clean models (Blueline Deluxe, Glass Tube, Vex Top-30, Boulevard Blues) stay nearly clean at low Gain. The high-gain models (Rectangle Triple, Furnace 50-50, Nu Rage, Dark Star 100) saturate hard. Output levels are roughly matched across models.

**Power amp.** There are ten models: Brit Iron 34, Yankee 6L6, Chime 84 Class A, Small Box 6V6, Big Bottle 88, Heavy Bottle 65, Transistor Slab, Spongy Rectifier, Brit Iron Modern and Single End 6V6. Each sets the drive range, push-pull asymmetry, rectifier sag, crossover, negative-feedback hardness, transformer bandwidth, speaker resonance and presence. `Master` pushes the power section from clean into saturation. `Presence` and `Depth` work like the power-amp feedback controls on a real amp.

**Cabinet and microphones.** The cabinet options are Direct, 1x12 Blue Open, 2x12 Open Jazz, 4x12 Vintage Thirty, 4x12 Greenie 25, 2x12 Brit Alnico and 4x10 Tweed. They are voiced with resonance, cone break-up and roll-off filters. Two microphones (Dynamic Cardioid, Ribbon Figure-8 or Large Condenser) can each be placed from the dust-cap centre (bright) to the cone edge (darker, thicker), set from 1 to 100 cm away, and angled off-axis.
- Close directional mics gain proximity bass.
- Distance adds arrival delay, so two mics at different distances comb against each other as real mics do. It also adds a floor reflection and some level loss.
- `Mic Layout` sends Mic A left and Mic B right (Stereo A-B), sums them (Mono Blend), or uses Mic A alone.
- `Room Mic` adds a distant ambience pair.

## Controls

- `Factory Preset`: Manual keeps every control live. The other presets set the chain, amp models, cabinet and amp knobs; effect settings always come from the effect controls.
- `Slot 1 ... Slot 12`: Which effect runs in each chain position (Off or one of the twelve effects).
- `Amp After Slot`: Where the amp sits in the chain: 0 puts it before every effect, 12 (default) after every effect.
- `Effects / Echo`: Time, Feedback, Tone, Wow, Mix.
- `Effects / Delay`: Time, Feedback, Tone, Mix.
- `Effects / Ping Pong`: Time, Feedback, Tone, Mix.
- `Effects / Chorus`: Rate, Depth, Mix.
- `Effects / Compressor`: Sustain, Attack, Release, Level, Blend (parallel mix).
- `Effects / Auto-Wah`: Sensitivity, Range, Resonance, Mix.
- `Effects / Phaser`: Rate, Depth, Feedback, Mix.
- `Effects / Flanger`: Rate, Depth, Manual, Feedback, Mix.
- `Effects / Tremolo`: Rate, Depth, Shape (sine to square), Stereo Pan.
- `Effects / Reverb`: Decay, Pre-Delay, Damping, Mix.
- `Effects / Noise Cancel`: Threshold, Range, Release, Hum Filter.
- `Effects / Fuzz Box`: Fuzz, Tone, Octave, Level.
- `Preamp`: Ten preamp models.
- `Power Amp`: Ten power-amp models.
- `Gain, Bass, Middle, Treble`: Preamp drive and tone stack.
- `Master, Presence, Depth`: Power-amp drive, top-end and low-end feedback voicing.
- `Amp Level`: Amp output level in dB.
- `Cabinet`: Direct or one of six speaker cabinets.
- `Mic Layout`: Stereo A-B, Mono Blend or Mic A Only.
- `Mic A / Mic B Type`: Dynamic Cardioid, Ribbon Figure-8 or Large Condenser.
- `Mic A / Mic B Position (Cap to Edge)`: 0 points at the dust cap (brightest), 1 at the cone edge (darkest).
- `Mic A / Mic B Distance`: 1 to 100 cm: closer adds proximity bass; farther adds delay, a floor reflection and lowers the level.
- `Mic A / Mic B Angle`: 0 to 60 degrees off-axis, rolling off treble.
- `Mic A / Mic B Level`: Level of each microphone in dB.
- `Room Mic`: Amount of distant room ambience.
- `Stereo Width`: Width of the final stereo image.
- `Output Level`: Final output level in dB, followed by a soft safety clipper.

## Factory presets

- `Manual`: Every control as set by hand.
- `Glassy Clean`: Blueline Deluxe into Yankee 6L6 with compression, chorus, delay and reverb on a 1x12.
- `Blues Breakup`: Boulevard Blues into Small Box 6V6 on a 2x12 Brit Alnico, pushed just into breakup, with compression, echo and reverb.
- `Plexi Classic Rock`: Plex Lead 59 into Brit Iron 34 on a 4x12 Greenie with a noise gate, delay and reverb.
- `Modern Metal`: Rectangle Triple into Heavy Bottle 65 on a 4x12 Vintage Thirty, with a noise gate, compression and delay.
- `Nu Metal Drop`: Nu Rage into Heavy Bottle 65 on a 4x12 Vintage Thirty with scooped mids and a tight gate.
- `Psych Fuzz Lead`: Fuzz Box, Auto-Wah, Phaser and Echo into Citrus Rocker and Brit Iron 34 on a 4x12 Greenie.
- `Ambient Swell`: Glass Tube Pre into Chime 84 Class A on a 2x12 Open Jazz with compression, chorus, ping-pong repeats and a long reverb.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-forge-rig-lv2
cmake --build build --target rtal-forge-rig-standalone
cmake --build build --target rtal-forge-rig-vst2
cmake --build build --target rtal-forge-rig-package
```
