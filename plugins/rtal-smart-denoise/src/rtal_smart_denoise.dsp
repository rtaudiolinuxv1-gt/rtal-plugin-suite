import("stdfaust.lib");

declare name "rtal-smart-denoise";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Smart de-noise: learns your rig's hiss and hum by itself and removes it band by band, leaving note tails untouched.";

//==========================================================================
// rtal_smart_denoise.h learns the noise profile and applies a smoothed
// Wiener gain per frequency bin. The output is delayed by the 2048-sample
// analysis window (about 43 ms at 48 kHz); the dry path is delayed to match
// so the Mix control does not comb.
//==========================================================================

presetMode = nentry("smart-denoise/[0]Factory Preset [style:menu{'Manual':0;'Studio Transparent':1;'Gentle Hiss':2;'Heavy Clean-up':3;'Live Stage':4}]", 0, 0, 4, 1);
pick(manual, p1, p2, p3, p4) = ba.selectn(5, int(presetMode), manual, p1, p2, p3, p4);

learnMode = nentry("smart-denoise/[1]Noise Profile/[1]Learning [style:menu{'Automatic':0;'Hold Profile':1}]", 0, 0, 1, 1);
learnNow = button("smart-denoise/[1]Noise Profile/[2]Learn Now (hold while silent)");
resetButton = button("smart-denoise/[1]Noise Profile/[3]Forget Profile");
noiseMeter = hbargraph("smart-denoise/[1]Noise Profile/[4]Noise Floor [unit:dB]", -120, 0);
learnMeter = hbargraph("smart-denoise/[1]Noise Profile/[5]Learning Activity", 0, 1);

reductionManual = hslider("smart-denoise/[2]Cleaning/[1]Reduction [unit:dB]", 18, 0, 50, 0.1);
sensitivityManual = hslider("smart-denoise/[2]Cleaning/[2]Sensitivity [style:knob]", 0.4, 0.0, 1.0, 0.01);
releaseManual = hslider("smart-denoise/[2]Cleaning/[3]Tail Release [unit:ms]", 200, 10, 1500, 1);
smoothingManual = hslider("smart-denoise/[2]Cleaning/[4]Smoothing [style:knob]", 0.5, 0.0, 1.0, 0.01);
reductionMeter = hbargraph("smart-denoise/[2]Cleaning/[5]Removing [unit:dB]", -50, 0);

listen = checkbox("smart-denoise/[3]Output/[1]Listen to Removed Noise");
mix = hslider("smart-denoise/[3]Output/[2]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
outLevel = hslider("smart-denoise/[3]Output/[3]Level [unit:dB]", 0, -30, 12, 0.1) : si.smoo;

// Presets: Manual, Studio Transparent, Gentle Hiss, Heavy Clean-up, Live Stage.
reduction = pick(reductionManual, 12, 10, 35, 20);
sensitivity = pick(sensitivityManual, 0.25, 0.3, 0.7, 0.5);
release = pick(releaseManual, 350, 250, 120, 150);
smoothing = pick(smoothingManual, 0.6, 0.5, 0.8, 0.4);

handle = fconstant(int rtal_dn_open, "rtal_smart_denoise.h") % 65536;
engine = ffunction(float rtal_dn_process(int, float, float, float, int, int, int, float, float, float, float, int), "rtal_smart_denoise.h", "");
info = ffunction(float rtal_dn_info(int, int, float), "rtal_smart_denoise.h", "");

latency = 2046;

process(l, r) = outL, outR
with {
  cleanL = engine(handle, l, r, ma.SR, int(learnMode), int(learnNow), int(resetButton), reduction, sensitivity,
                  release, smoothing, int(listen));
  cleanR = info(handle, 0, cleanL);
  floorDb = info(handle, 1, cleanL);
  removing = info(handle, 2, cleanL);
  learningNow = info(handle, 3, cleanL);
  dryL = l : de.delay(4096, latency);
  dryR = r : de.delay(4096, latency);
  gain = ba.db2linear(outLevel);
  outL = (dryL * (1.0 - mix) + cleanL * mix) * gain
    : attach(_, floorDb : noiseMeter) : attach(_, removing : reductionMeter) : attach(_, learningNow : learnMeter);
  outR = (dryR * (1.0 - mix) + cleanR * mix) * gain;
};
