(
{
	var input = SoundIn.ar(0);
	var attack = HPZ1.ar(Amplitude.ar(input, 0.001, 0.1)).max(0);
	var pings = Ringz.ar(input * attack * 12, [2200, 3400, 4800], 0.08);
	Splay.ar([input * 0.75, Mix(pings) * 0.4], 0.8);
}.play;
)
