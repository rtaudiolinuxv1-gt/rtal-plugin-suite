(
{
	var input = SoundIn.ar(0);
	var taps = Mix.fill(4, { |i|
		var delay = [0.08, 0.13, 0.19, 0.27][i];
		var sig = DelayC.ar(input, 0.4, delay + SinOsc.kr(0.1 + i * 0.05).range(0, 0.01));
		Resonz.ar(sig, 300 + i * 600, 0.04)
	});
	Splay.ar([input * 0.6, taps * 0.5], 0.7);
}.play;
)
