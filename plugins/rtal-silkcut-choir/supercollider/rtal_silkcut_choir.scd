(
{
	var input = SoundIn.ar(0);
	var pitch = Pitch.kr(input)[0].clip(80, 900).lag(0.15);
	var choir = Mix.fill(4, { |i|
		var sig = DelayC.ar(input, 0.1, 0.01 + i * 0.006 + SinOsc.kr(0.1 + i * 0.04).range(0, 0.003));
		Resonz.ar(sig, pitch * [0.96, 1.0, 1.05, 1.12][i], 0.04)
	});
	Splay.ar([input * 0.65, choir * 0.4], 0.75);
}.play;
)
