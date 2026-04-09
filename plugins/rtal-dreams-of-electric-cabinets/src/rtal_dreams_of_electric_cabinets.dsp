import("stdfaust.lib");

declare name "rtal-dreams-of-electric-cabinets";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Impossible cabinet morphing resonator.";

presetMode = nentry("dreams-of-electric-cabinets/[0]Factory Preset [style:menu{'Manual':0;'Blue Room':1;'Paper Cone':2;'Burned Arcade':3}]", 0, 0, 3, 1);
bodyManual = hslider("dreams-of-electric-cabinets/[1]Body [style:knob]", 0.44, 0.0, 1.0, 0.01) : si.smoo;
coneManual = hslider("dreams-of-electric-cabinets/[2]Cone [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
boxManual = hslider("dreams-of-electric-cabinets/[3]Box [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
sparkManual = hslider("dreams-of-electric-cabinets/[4]Spark [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
warpManual = hslider("dreams-of-electric-cabinets/[5]Warp [style:knob]", 0.26, 0.0, 1.0, 0.01) : si.smoo;
roomManual = hslider("dreams-of-electric-cabinets/[6]Room [style:knob]", 0.32, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("dreams-of-electric-cabinets/[7]Mix [style:knob]", 0.58, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBlue = (presetMode >= 0.5) * (presetMode < 1.5);
isPaper = (presetMode >= 1.5) * (presetMode < 2.5);
isBurned = presetMode >= 2.5;

selectPreset(manual, blue, paper, burned) =
  manual * isManual +
  blue * isBlue +
  paper * isPaper +
  burned * isBurned;

body = selectPreset(bodyManual, 0.58, 0.30, 0.72);
cone = selectPreset(coneManual, 0.38, 0.62, 0.74);
box = selectPreset(boxManual, 0.42, 0.50, 0.80);
spark = selectPreset(sparkManual, 0.26, 0.54, 0.82);
warp = selectPreset(warpManual, 0.18, 0.30, 0.70);
room = selectPreset(roomManual, 0.44, 0.20, 0.62);
mix = selectPreset(mixManual, 0.46, 0.54, 0.68);

process = _,_ : cabinetStereo
with {
  cabinetStereo(inL, inR) = outL, outR
  with {
    mono = ((inL + inR) * 0.5) : fi.highpass(1, 55.0);
    stage1 = mono : fi.resonbp(120.0 + body * 260.0, 1.8 + box * 4.0, 1.0);
    stage2 = mono : fi.resonbp(500.0 + cone * 1700.0 + warp * 600.0, 1.8 + cone * 8.0, 1.0);
    stage3 = mono : fi.resonbp(1800.0 + spark * 4200.0, 2.0 + spark * 10.0, 1.0);
    colored = stage1 * 0.6 + stage2 * 0.8 + stage3 * 0.4;
    wobble = os.osc(0.08 + warp * 0.21) * (0.05 + warp * 0.25);
    warped = colored * (1.0 + wobble) + de.fdelay5(8192, 18.0 + warp * 42.0, colored) * (0.08 + warp * 0.22);
    roomL = fi.lowpass(2, 2200.0 + spark * 5200.0, warped) + de.fdelay5(8192, 80.0 + room * 420.0 + warp * 40.0, warped) * (room * 0.35);
    roomR = fi.lowpass(2, 2500.0 + spark * 5400.0, warped) + de.fdelay5(8192, 96.0 + room * 470.0 + warp * 55.0, warped) * (room * 0.35);
    coneEdge = warped : fi.highpass(1, 1400.0 + spark * 2000.0) : *(0.08 + spark * 0.2);
    outL = ma.tanh(inL * (1.0 - mix) + (roomL + coneEdge) * mix);
    outR = ma.tanh(inR * (1.0 - mix) + (roomR + coneEdge * (0.85 + warp * 0.2)) * mix);
  };
};
