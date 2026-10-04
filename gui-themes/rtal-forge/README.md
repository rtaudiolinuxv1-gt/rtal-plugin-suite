# RTAL Forge: bitmap theme for Faust plugin dialogs

This is a complete set of bitmaps for replacing the standard toolkit graphics of a Faust-generated dialog. It covers knobs, sliders, buttons, checkboxes and switches, radio buttons, LEDs, numeric entries, menus, bargraph meters, group frames and tabs, plus a default panel background. The look is a dark brushed-metal panel with aluminium knobs and an amber accent.

![Preview](preview_dialog.png)

Every image is rendered by `generate.py`, so the theme can be re-coloured or re-rendered:

```bash
pip install pillow numpy
python3 generate.py                   # amber accent, 1x and 2x
python3 generate.py --accent 3ec8ff   # cyan accent
python3 generate.py --scales 1,2,3    # add a 3x set
```

`contact_sheet.png` shows every asset, and `theme.json` describes each one: its files, size, frame count, nine-slice insets and hotspots. `theme.json` also maps every Faust widget to its images.

## Conventions

- **Formats and sizes.** PNG with alpha, sRGB. Images are provided at `1x/` and `2x/` (HiDPI). Sizes and insets in `theme.json` are 1x pixels; the 2x files are exactly double.
- **Knob filmstrips.** Vertical strips of square frames: 101 frames from minimum (frame 0) to maximum (frame 100), so value `v` in 0..1 uses frame `round(v * 100)`. The sweep is 270 degrees, from -135 to +135 with 0 at 12 o'clock. The 2x large strip is 16160 px tall, within the common 16384 px texture limit.
- **Rotating knobs.** If your toolkit rotates a pointer instead of using a filmstrip, draw `knob_*_base.png` and rotate `knob_*_pointer.png` about its centre across the same sweep.
- **Nine-slice.** `[left, top, right, bottom]` insets stay unscaled; the middle stretches. Edge lighting lives entirely inside the insets, so stretched frames show no seams.
- **Bargraphs and slider fills.** Draw the `_off` image or the track, then the `_on` image or fill clipped to the value: from the bottom for vertical, from the left for horizontal.
- **No text.** Labels, values and menu items are left to your toolkit's font rendering.

## Widget map

| Faust widget | Images |
| --- | --- |
| `hslider`, `vslider` | `sliders/*_track`, `*_fill`, `*_thumb` and `groups/value_display` |
| `[style:knob]` | `knobs/knob_large_strip` (80 px), `knob_medium_strip` (56 px), `knob_small_strip` (36 px); `knob_medium_bipolar_strip` for ranges like -1..1, where the arc grows from 12 o'clock |
| `nentry` | `entries/nentry_box`, `nentry_up_*`, `nentry_down_*` (normal and pressed) |
| `[style:menu{...}]` | `menus/menu_box`, `menu_arrow`, `menu_popup`, `menu_item_highlight` |
| `[style:radio{...}]` | `toggles/radio_off`, `radio_on` |
| `button` | `buttons/button_normal`, `button_hover`, `button_pressed` |
| `checkbox` | `toggles/checkbox_off`/`_on`, or the `switch_off`/`_on` toggle as an alternative |
| `hbargraph`, `vbargraph` | `meters/*bargraph_off`, `*bargraph_on` (24 LED segments: green, yellow, red) |
| `[style:led]` | `leds/led_{amber,green,red}_{off,on}` |
| `hgroup`, `vgroup` | `groups/group_frame`, `groups/label_plate` |
| `tgroup` | `groups/tab_normal`, `groups/tab_active` with `groups/group_frame` |
| Dialog background | `background/panel_default` (1200x800, with a 44 px header band) or the seamless `background/panel_tile` |

(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
