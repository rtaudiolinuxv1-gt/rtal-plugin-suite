import("stdfaust.lib");

declare name "rtal-guitar-shadow";
declare version "1.0.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Gesture-reactive guitar shadow effect for guitar.";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare options "[nvoices:0]";

presetMode = nentry("guitar-shadow/[0]Factory Preset [style:menu{'Manual':0;'Ghost Doubler':1;'Bending Halo':2;'Broken Constellation':3}]", 0, 0, 3, 1);
shadowManual = hslider("guitar-shadow/[1]Shadow [style:knob] [midi:ctrl 20]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
bloomManual = hslider("guitar-shadow/[2]Bloom [style:knob] [midi:ctrl 21]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
bendSensitivityManual = hslider("guitar-shadow/[3]Bend Sensitivity [style:knob] [midi:ctrl 22]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
harmonicSpreadManual = hslider("guitar-shadow/[4]Harmonic Spread [style:knob] [midi:ctrl 23]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
decayManual = hslider("guitar-shadow/[5]Decay [style:knob] [midi:ctrl 24]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("guitar-shadow/[6]Width [style:knob] [midi:ctrl 25]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("guitar-shadow/[7]Mix [style:knob] [midi:ctrl 26]", 0.35, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isGhost = (presetMode >= 0.5) * (presetMode < 1.5);
isHalo = (presetMode >= 1.5) * (presetMode < 2.5);
isConstellation = presetMode >= 2.5;

selectPreset(manual, ghost, halo, constellation) =
    manual * isManual +
    ghost * isGhost +
    halo * isHalo +
    constellation * isConstellation;

shadow = selectPreset(shadowManual, 0.28, 0.58, 0.82);
bloom = selectPreset(bloomManual, 0.22, 0.54, 0.80);
bendSensitivity = selectPreset(bendSensitivityManual, 0.48, 0.78, 0.70);
harmonicSpread = selectPreset(harmonicSpreadManual, 0.18, 0.40, 0.72);
decay = selectPreset(decayManual, 0.30, 0.52, 0.76);
width = selectPreset(widthManual, 0.62, 0.74, 0.90);
mix = selectPreset(mixManual, 0.22, 0.36, 0.48);

process = _,_ : stereoGhostBend
with {
    maxDelay = 16384;

    stereoGhostBend(inL, inR) = outL, outR
    with {
        dryL = inL;
        dryR = inR;
        monoIn = ((inL + inR) * 0.5) : fi.highpass(2, 60.0);

        env = monoIn : an.amp_follower_ar(0.004, 0.120) : min(1.0);
        attack = max(0.0, env - env') : *(12.0) : min(1.0) : an.amp_follower_ar(0.003, 0.060);
        transient = max(0.0, monoIn - (monoIn : fi.lowpass(2, 1000.0 + bloom * 2600.0)));

        rawPitch = monoIn : an.pitchTracker(4, 0.040) : max(55.0) : min(1760.0);
        rawPitchDelta = abs(ma.log2((rawPitch + 1.0) / (rawPitch' + 1.0)));
        trackingConfidence = min(1.0, max(0.0, (env - 0.012) * 28.0)) * max(0.0, 1.0 - rawPitchDelta * 10.0);
        trackedPitch = rawPitch : ba.sAndH(trackingConfidence > 0.20) : si.smooth(ba.tau2pole(0.030));

        bendEnergy = min(1.0, rawPitchDelta * (18.0 + bendSensitivity * 90.0)) : an.amp_follower_ar(0.005, 0.180);
        vibratoEnergy = abs(trackedPitch - trackedPitch : si.smooth(ba.tau2pole(0.090)))
            : /(max(1.0, trackedPitch))
            : *(24.0)
            : min(1.0)
            : an.amp_follower_ar(0.015, 0.220);
        gestureMotion = min(1.0, bendEnergy * 0.7 + vibratoEnergy * 0.5 + attack * 0.25);

        period = (ma.SR / max(70.0, trackedPitch)) : min(float(maxDelay - 64));
        tailDrive = env : an.amp_follower_ar(0.001, 0.300 + decay * 1.800);
        wetDrive = min(1.0, tailDrive * (0.48 + bloom * 0.8) + gestureMotion * 0.5 + transient * (0.18 + bloom * 0.45));

        voice1 = shadowVoice(monoIn, 0.82, -0.95, 0.22);
        voice2 = shadowVoice(monoIn, 0.96, -0.40, 0.44);
        voice3 = shadowVoice(monoIn, 1.08, 0.35, 0.56);
        voice4 = shadowVoice(monoIn, 1.26, 0.90, 0.72);

        wetMono = (voice1 + voice2 + voice3 + voice4) * (0.28 + shadow * 0.62);
        shimmer = wetMono : fi.highpass(1, 1600.0 + bloom * 2200.0) : de.fdelay5(maxDelay, 14.0 + gestureMotion * 45.0 + decay * 38.0) : *(0.10 + bloom * 0.28 + gestureMotion * 0.18);
        wetTone = (wetMono + shimmer) : fi.lowpass(2, 5400.0 + bloom * 4200.0) : fi.highpass(1, 120.0);
        wetSat = wetTone : *(1.0 + shadow * 1.6 + bloom * 0.7) : ma.tanh : *(0.85);

        orbitRateA = 0.06 + gestureMotion * (0.20 + bendSensitivity * 0.55);
        orbitRateB = 0.11 + gestureMotion * (0.15 + width * 0.32);
        orbitA = os.osc(orbitRateA) * (0.10 + width * 0.28);
        orbitB = os.osc(orbitRateB) * (0.06 + width * 0.18);
        panBase = width * 0.65 + gestureMotion * 0.25;
        panL = min(1.0, max(0.0, 0.5 + orbitA * panBase - orbitB * 0.25));
        panR = min(1.0, max(0.0, 0.5 - orbitA * panBase + orbitB * 0.25));

        edgeL = wetSat : fi.highpass(1, 1800.0 + width * 1500.0) : de.fdelay5(maxDelay, 9.0 + width * 18.0 + gestureMotion * 10.0) : *(0.05 + width * 0.12);
        edgeR = wetSat : fi.highpass(1, 2000.0 + width * 1700.0) : de.fdelay5(maxDelay, 13.0 + width * 24.0 + gestureMotion * 16.0) : *(0.05 + width * 0.12);
        wetL = wetSat * panL + edgeL;
        wetR = wetSat * panR + edgeR;

        mixAmt = mix;
        summedL = dryL * (1.0 - mixAmt) + wetL * mixAmt;
        summedR = dryR * (1.0 - mixAmt) + wetR * mixAmt;
        outL = summedL : fi.highpass(1, 20.0) : *(0.95) : ma.tanh;
        outR = summedR : fi.highpass(1, 20.0) : *(0.95) : ma.tanh;

        shadowVoice(x, ratio, skew, phase) = voiceOut
        with {
            spread = 0.03 + harmonicSpread * 0.58;
            detuneRatio = max(0.55, ratio + skew * spread * 0.55);
            centerHz = max(120.0, min(5800.0, trackedPitch * detuneRatio + trackedPitch * gestureMotion * abs(skew) * 0.18));
            q = 3.0 + bloom * 7.0 + abs(skew) * 1.5;
            delaySamples = min(float(maxDelay - 1),
                period * (0.18 + abs(skew) * (0.22 + shadow * 0.30))
                + gestureMotion * (24.0 + 90.0 * abs(skew))
                + 6.0 + phase * 18.0);
            modRate = 0.05 + phase * 0.09 + bendSensitivity * 0.08;
            microShift = os.osc(modRate) * (2.0 + width * 10.0 + gestureMotion * 20.0);
            excited = x * (0.4 + env * 0.28) + transient * (0.14 + gestureMotion * 0.45 + abs(skew) * 0.08);
            delayed = excited : de.fdelay5(maxDelay, delaySamples + microShift);
            resonant = delayed : fi.resonbp(centerHz, q, 1.0);
            shadowTail = resonant : de.fdelay5(maxDelay, 11.0 + phase * 16.0 + decay * 55.0) : *(0.08 + decay * 0.18 + bloom * 0.08);
            voiceGain = (0.14 + abs(skew) * 0.10 + shadow * 0.16) * wetDrive;
            voiceOut = (resonant + shadowTail) * voiceGain;
        };
    };
};
