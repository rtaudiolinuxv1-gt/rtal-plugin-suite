(
{
	var input = SoundIn.ar(0);
	var env = Amplitude.kr(input, 0.005, 0.12);
	var driven = tanh((input * (3 + env * 10)) + (env - 0.5) * 0.2);
	XFade2.ar(input, HPF.ar(driven, 50), 0.8);
}.play;
)
