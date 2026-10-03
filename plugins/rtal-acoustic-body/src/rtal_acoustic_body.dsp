import("stdfaust.lib");

declare name "rtal-acoustic-body";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Electric-to-acoustic simulator: wooden body resonances, top brightness, pick attack and a small room.";

presetMode = nentry("acoustic-body/[0]Factory Preset [style:menu{'Manual':0;'Dreadnought':1;'Parlour':2;'Jumbo Strummer':3}]", 0, 0, 3, 1);
bodyManual = nentry("acoustic-body/[1]Body [style:menu{'Dreadnought':0;'Parlour':1;'Jumbo':2;'Nylon Classical':3}]", 0, 0, 3, 1);
resonanceManual = hslider("acoustic-body/[2]Body Resonance [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
topManual = hslider("acoustic-body/[3]Top [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
attackManual = hslider("acoustic-body/[4]Pick Attack [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
scoopManual = hslider("acoustic-body/[5]Magnetic Scoop [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
roomManual = hslider("acoustic-body/[6]Room [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("acoustic-body/[7]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("acoustic-body/[8]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isDread = (presetMode >= 0.5) * (presetMode < 1.5);
isParlour = (presetMode >= 1.5) * (presetMode < 2.5);
isJumbo = presetMode >= 2.5;

selectPreset(manual, dread, parlour, jumbo) =
  manual * isManual +
  dread * isDread +
  parlour * isParlour +
  jumbo * isJumbo;

body = int(selectPreset(bodyManual, 0, 1, 2));
resonance = selectPreset(resonanceManual, 0.65, 0.55, 0.75);
top = selectPreset(topManual, 0.55, 0.65, 0.50);
attack = selectPreset(attackManual, 0.45, 0.55, 0.40);
scoop = selectPreset(scoopManual, 0.55, 0.45, 0.60);
room = selectPreset(roomManual, 0.20, 0.15, 0.25);
level = selectPreset(levelManual, 0.50, 0.50, 0.50);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : bodyStereo
with {
  // Body modes per guitar: air (Helmholtz) resonance, main top mode and a
  // second top/back mode. Values in Hz.
  airHz = ba.selectn(4, body, 98.0, 125.0, 90.0, 110.0);
  topHz = ba.selectn(4, body, 195.0, 240.0, 180.0, 210.0);
  backHz = ba.selectn(4, body, 380.0, 460.0, 340.0, 400.0);
  brightHz = ba.selectn(4, body, 3200.0, 3800.0, 3000.0, 2400.0);

  // Magnetic pickups have a strong mid hump the acoustic doesn't; Scoop removes it.
  depickup = fi.peak_eq_cq(0.0 - scoop * 9.0, 1800.0, 0.9) : fi.peak_eq_cq(0.0 - scoop * 4.0, 700.0, 1.2);

  // Body resonances add a little ring to each mode.
  modes = fi.peak_eq_cq(resonance * 6.0, airHz, 4.0)
    : fi.peak_eq_cq(resonance * 5.0, topHz, 3.5)
    : fi.peak_eq_cq(resonance * 4.0, backHz, 3.0);

  // The top: piezo-like sparkle and the nylon-string roll-off.
  topTone = fi.high_shelf((top - 0.3) * 9.0, brightHz) : fi.lowpass(2, ba.if(body == 3, 7000.0, 15000.0));

  bodyStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5 : fi.highpass(2, 70.0);
    fast = mono : abs : an.amp_follower_ar(0.0003, 0.02);
    slow = mono : abs : an.amp_follower_ar(0.01, 0.02);
    // Pick attack: brief brightness lift on each transient.
    transient = max(0.0, fast - slow) / max(slow, 0.001) : min(1.0);
    picked = mono + (mono : fi.highpass(2, 2500.0)) * transient * attack * 1.2;
    acoustic = picked : depickup : modes : topTone;
    roomSend = acoustic * room;
    reflect(ms) = de.fdelay(8192, ms * 0.001 * ma.SR);
    roomL = roomSend : fi.lowpass(1, 6000.0) <: reflect(7.1), reflect(13.3), reflect(19.7) :> *(0.25);
    roomR = roomSend : fi.lowpass(1, 6000.0) <: reflect(8.9), reflect(11.9), reflect(23.1) :> *(0.25);
    g = 0.25 + level * level * 1.1;
    outL = inL * (1.0 - mix) + (acoustic + roomL) * g * mix;
    outR = inR * (1.0 - mix) + (acoustic + roomR) * g * mix;
  };
};
