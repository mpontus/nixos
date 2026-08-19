# XFCE panel border findings

## Goal

Render a continuous, rounded two-pixel `#b75681` outline around each XFCE top-panel island while preserving real XFCE widgets, XEmbed plugins, global menus, tray icons, and click targets.

The active configuration uses a native two-pixel X11 panel border applied by XMonad. The border sits outside each panel client area, so XEmbed children cannot overlap it; Picom clips the complete native frame to the configured radius.

## Proven window structure

Each island has a panel-owned X window and may contain several separately composited external-plugin windows.

```text
X root
└── xfce4-panel PanelWindow, 368×36 at (11,23)       panel process
    ├── in-process panel widgets, such as clock
    └── GtkSocket
        └── wrapper-2.0 GtkPlug, e.g. 289×34 at (50,24)  wrapper process
            └── plugin widgets, such as the appmenu menubar
```

The appmenu wrapper is one pixel inside the panel on each occupied edge. The relevant XFCE allocation code starts from the full panel allocation and increments `x`/`y` by one and decrements width/height by one for every active panel border edge. Therefore, a wrapper can occupy the second physical pixel of a two-pixel CSS border.

Relevant source:

- `panel/panel-window.c` in `/tmp/xfce4-panel-src/`
- `wrapper/wrapper-plug-x11.c` in `/tmp/xfce4-panel-src/`
- https://gitlab.xfce.org/xfce/xfce4-panel/-/blob/master/panel/panel-window.c
- https://gitlab.xfce.org/xfce/xfce4-panel/-/blob/master/wrapper/wrapper-plug-x11.c

`WrapperPlugX11` requests an RGBA visual and names its GtkPlug `XfcePanelWindowWrapper`. It can therefore compose transparent pixels; it is not intrinsically limited to an opaque RGB visual.

## Pixel evidence

Panel geometry is stable at top `y=23`, height `36`, with nominal border rows:

```text
outer top:    y=23
inner top:    y=24
inner bottom: y=57
outer bottom: y=58
```

With a focused terminal's appmenu, the interior probe at `x=100` produced:

```text
x=100,y=23 = #b75681
x=100,y=24 = #131c2b
x=100,y=57 = #131c2b
x=100,y=58 = #b75681
```

The appmenu wrapper physically occupies the overlap region, but the first unmap result did not identify the navy painter. Unmapping the visible `289×34` appmenu wrapper changed the probe to:

```text
x=100,y=23 = #b75681
x=100,y=24 = #b75681
x=100,y=40 = #0e1624
x=100,y=57 = #b75681
x=100,y=58 = #b75681
```

Remapping the wrapper immediately restored `#131c2b` at `y=24` and `y=57` plus the appmenu content. Later raw-drawable capture corrected the interpretation: every inspected wrapper edge is ARGB `0x00000000`, not opaque navy. Unmapping causes the parent to repaint the exposed region, so it cannot by itself prove that the wrapper painted the former navy.

The `#131c2b` color is the desktop/root background: samples at `(100,15)` and `(500,200)` exactly match it. In state B, raw panel-interior pixels beneath mapped native children are also `0x00000000`; transparent `GtkSocket`/`GtkPlug` regions therefore expose the desktop through an unpainted parent-child hole. Unmapping the child damages and repaints the parent, yielding the rose rows and `#0e1624` body seen in the earlier test.

There is no `_NET_WM_WINDOW_OPACITY` property on panel or wrapper windows. A temporary `GTK_THEME=Adwaita` probe was inherited by the wrapper but left the desktop-colored hole unchanged; ordinary Adwaita-dark fill is not its source.

Right-island ownership is split:

```text
power:  panel GtkSocket 34×34 @ (971,24)
        └── wrapper-2.0 34×34 @ (971,24)

status: panel GtkSocket 35×34 @ (753,24)
        └── wrapper-2.0 35×34 @ (753,24)
            └── snixembed 22×22 @ (759,30)
```

Power and status native children still create the physical overlap: all are allocated at `+1,+1`, spanning the second border row. Raw B-state captures show appmenu, status, power, and the status socket each have 32-bit TrueColor visuals, `backing_pixel=0`, and transparent edge pixels (`0x00000000`). Status has both socket and wrapper layers, so either mapped layer can keep the parent region unpainted; it is not evidence of two opaque navy painters.

Representative screenshots:

- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-baseline-20260819-172519.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-unmap2-20260819-172542.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-remap2-20260819-172545.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-q2B-20260819-182024.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-q2green-20260819-182523.png`

## Tested CSS approaches

### Wrapper and descendant resets

A fully transparent wrapper root removes the appmenu's visible dark-gray `#353535` fill but exposes the root background through the wrapper's overlap. Descendant resets are still used for plugin chrome; they are not sufficient to paint the inner outline row.

### Q1: root `background-image` attribution

The earlier claim that root `background-image: none` made appmenu text disappear was false. It came from a multi-variable screenshot and was not isolated.

Four isolated fresh-VM states all launched a focused terminal, retained a live mapped `289×34` appmenu wrapper, showed its `File Edit View Terminal Tabs Help` labels, and had no CSS parse error in the user journal. The corrected white-glyph probe (`R`, `G`, and `B` each above `230`) found 41 label pixels in every state:

| State | Parent selector | Wrapper root rule | Evidence |
|---|---|---|---|
| A | `#XfcePanelWindow` | `background-color: transparent` | `qemu-xfce-q1A-20260819-180930.png` |
| B | `#XfcePanelWindow` | A plus `background-image: none` | `qemu-xfce-q1B-20260819-181210.png` |
| C | `.xfce4-panel.background` | none | `qemu-xfce-q1C-20260819-181453.png` |
| D | `.xfce4-panel.background` | B plus `window#...` and `plug#...` selectors | `qemu-xfce-q1D-20260819-181738.png` |

The earlier root2 screenshot has zero white label pixels. Re-running its recovered CSS and original timing (`12s` after SSH, terminal launch, `4s` later) reproduced the blank appmenu and dark overlap state, but not a fully settled plugin tree: one tray icon was already present while other plugin wrappers had not yet mapped. The same CSS is populated after settling. Thus startup timing demonstrably contributes, but the historical fully mapped empty-plugin state is not proven to be only a startup race.

### Broad `.xfce4-panel` reset

A reset of `.xfce4-panel` was not a panel-internal-container selector. It also matched wrapper plugs, removed external-plugin visuals, and left the inner rows navy. It was reverted.

### Panel COLOR background with alpha zero

Setting a panel to XFCE `background-style=COLOR` with `background-rgba=rgba(0,0,0,0)` did send a transparent color through XFCE's wrapper path. However, XFCE's local background provider then displaced the CSS parent fill, making the island itself disappear. It was reverted.

### Light-theme probe

A temporary VM-only `GTK_THEME=Adwaita` was inherited by `wrapper-2.0`. The navy inner-row pixels remained `#131c2b`. The probe was reverted.

### Q2: navy-pixel attribution

State B root captures show `#131c2b` throughout every uncovered wrapper span. Raw per-window capture settles the apparent contradiction: appmenu, status, power, and status-socket edge and body-background pixels are `0x00000000` ARGB, while real plugin content has an `0xff` high byte. The desktop/root samples are exactly `#131c2b`; this is a compositing hole, not a wrapper-surface fill.

All inspected windows have 32-bit TrueColor visuals, zero border width, `backing_store=0`, `backing_pixel=0`, and no `_NET_WM_WINDOW_OPACITY`. `xwd` and Python Xlib were added temporarily to obtain these attributes and raw ZPixmap pixels, then removed. Neither XFCE source nor installed Adwaita files contains a literal `#131c2b`; arithmetic enumeration also found no source-over, pairwise mix, or RGB-scale formula within ±1 channel from the known palette (`#0e1624`, `#353535`, `#b75681`, `#f4effa`, black, white).

The CSS-reach probe changed the wrapper root `background-color` to `#00ff00`; external-wrapper content no longer rendered in the resulting capture (`qemu-xfce-q2green-20260819-182523.png`). This proves root styling materially affects wrapper rendering, but does not alter the raw-alpha conclusion.

### `!important`

This GTK3 build logged parse errors for attempted declarations containing `!important`, including `Junk at end of value for background`. No persistent configuration uses it. GTK's CSS overview documents selectors, `rgba`, and `transparent`, but does not include `!important` in its declaration grammar: https://docs.gtk.org/gtk3/css-overview.html.

## Attribution and accepted native-border repair

The dark right-island regions are root exposure, not paint from a socket or wrapper. In a fully mapped synthetic blank-content state, changing the root background to `#00ff00` turned both status and power overlap samples green. Changing panel body/border to magenta/cyan left those same samples at root `#131c2b`. Raw XPixmap samples for each status/power socket and wrapper were `0x00000000` ARGB; a wrapper-root `#ff8800` sentinel then turned both overlap samples orange.

GTK `box-shadow` and `outline` probes could not create an outside outline: X clipped both at the panel drawable bounds. A native X11 border succeeded. XMonad now applies `border_width=2` and ARGB pixel `0xffb75681` when each `Xfce4-panel` window is managed, then offsets the outer frame by two pixels. The GTK panel client stays 36 pixels high and contains no border; native children therefore cannot cover the outline. Picom rounds the complete client-plus-border frame.

All panels are content-fit (`length=1`, `length-adjust=true`). Balanced spacing uses 16-pixel outer-edge padding, compact internal status spacing, and 0.67 icon transforms (approximately 16 rendered pixels). After `xfce4-panel -r`, all four visible panel windows retained `Border width: 2`; appmenu click and power tooltip still worked. Evidence: `qemu-xfce-nativeborder-corrected-20260819-200933.png`, `qemu-xfce-balanced-20260819-203500.png`, `qemu-xfce-balanced-restart-20260819-203544.png`, `qemu-xfce-balanced-menu-20260819-203617.png`, and `qemu-xfce-balanced-power-hover-20260819-203619.png`.

## Deliberately not implemented

No XFCE/Picom source patch, XShape/helper process, overlay painter, GTK module, or pre-rendered asset was added.

## Reproduction and validation

The configuration source of truth is `readme.org`; `configuration.nix` is tangled output.

```sh
cd /home/mpontus/projects/nixpkgs
emacs --batch readme.org --eval "(require 'org)" --eval '(org-babel-tangle)'
nix-instantiate --parse configuration.nix
nixos-rebuild build-vm --flake .#nixos
```

Use a fresh qcow2 image, open a terminal to populate the global appmenu, capture the root window, and inspect `x=100` at rows `23`, `24`, `57`, and `58`.
