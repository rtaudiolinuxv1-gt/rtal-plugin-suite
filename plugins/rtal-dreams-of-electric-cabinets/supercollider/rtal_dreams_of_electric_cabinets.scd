(
{
	var input = SoundIn.ar(0);
	var low = Resonz.ar(input, 180, 0.09) * 0.7;
	var mid = Resonz.ar(input, 900, 0.05) * 0.8;
	var top = Resonz.ar(input, 2800, 0.03) * 0.4;
	(input * 0.4) + low + mid + top;
}.play;
)
