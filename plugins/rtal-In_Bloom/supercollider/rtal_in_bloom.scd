(
{
	var input = SoundIn.ar(0);
	var env = Amplitude.kr(input, 0.01, 0.2);
	var chain = Mix.fill(4, { |i|
		var ratio = [0.98, 1.25, 1.5, 2.0][i];
		var freq = Pitch.kr(input)[0].clip(70, 1400) * ratio;
		Resonz.ar(DelayC.ar(input, 0.2, 0.02 + i * 0.015), freq, 0.02 + env * 0.08)
	});
	Splay.ar([input * 0.6, chain * 0.5], 0.55);
}.play;
)
