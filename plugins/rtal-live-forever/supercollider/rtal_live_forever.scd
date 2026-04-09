(
{
	var input = SoundIn.ar(0);
	var env = Amplitude.kr(input, 0.01, 0.2);
	var delayed = DelayC.ar(input, 0.3, 0.12);
	var feed = Resonz.ar(delayed, Pitch.kr(input)[0].clip(90, 1000), 0.03) * env;
	Splay.ar([input * 0.6, feed * 0.8], 0.6);
}.play;
)
