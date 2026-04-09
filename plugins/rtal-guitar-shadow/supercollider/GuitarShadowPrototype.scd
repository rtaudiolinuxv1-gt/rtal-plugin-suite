(
// Reference sketch for tuning the guitar-shadow behavior in SuperCollider.
// This is not the production DSP path; use it to audition gesture mapping ideas.

s.waitForBoot({
    var sourceBus = Bus.audio(s, 1);
    var wetBus = Bus.audio(s, 2);

    SynthDef(\ghostInput, { |out = 0|
        var input = SoundIn.ar(0);
        Out.ar(out, HPF.ar(input, 60));
    }).add;

    SynthDef(\guitarShadowPrototype, {
        |inBus = 0, out = 0, shadow = 0.45, bloom = 0.4, bendSensitivity = 0.6,
         spread = 0.35, decay = 0.45, width = 0.7, mix = 0.35|
        var input = In.ar(inBus, 1);
        var amp = Amplitude.kr(input, 0.01, 0.12).clip(0, 1);
        var freq = Pitch.kr(input, ampThreshold: 0.01, median: 7).at(0).clip(55, 1760);
        var motion = HPZ1.kr(freq).abs.linlin(0, 6, 0, 1).clip(0, 1);
        var baseDelay = (SampleRate.ir / freq.max(70)).clip(8, 2048);
        var voices = Mix.fill(4, { |i|
            var skew = [-0.95, -0.4, 0.35, 0.9][i];
            var ratio = [0.82, 0.96, 1.08, 1.26][i];
            var detuned = freq * (ratio + skew * (0.03 + (spread * 0.58) * 0.55));
            var delay = (baseDelay * (0.18 + skew.abs * (0.22 + shadow * 0.30))
                + motion * (24 + 90 * skew.abs)
                + (i * 12)).clip(1, 4096);
            var shifted = DelayC.ar(input, 0.1, delay / SampleRate.ir)
                * (0.14 + skew.abs * 0.10 + shadow * 0.16);
            BPF.ar(shifted, detuned.clip(120, 5800), (3 + bloom * 7 + skew.abs * 1.5).reciprocal);
        });
        var wet = tanh(voices * (0.55 + bloom * 0.85 + motion * 0.55));
        var lfo = SinOsc.kr(0.06 + motion * (0.2 + bendSensitivity * 0.55));
        var stereo = Balance2.ar(wet, wet, lfo * (width * 0.7));
        Out.ar(out, XFade2.ar(input ! 2, stereo, mix.linlin(0, 1, -1, 1)));
    }).add;

    s.sync;

    x = Synth(\ghostInput, [\out, sourceBus]);
    y = Synth.after(x, \guitarShadowPrototype, [\inBus, sourceBus, \out, 0]);
});
)
