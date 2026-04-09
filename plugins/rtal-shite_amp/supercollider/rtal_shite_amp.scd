(
{
	var input = SoundIn.ar(0);
	var env = Amplitude.kr(input, 0.01, 0.15);
	var sag = 1 - (env * 0.5);
	var amp = tanh(input * (8 * sag) + SinOsc.ar(7, 0, 0.02));
	LPF.ar(amp, 3200) * 0.7;
}.play;
)
