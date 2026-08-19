# XFCE panel border findings

## Goal

Render a continuous, rounded two-pixel `#b75681` outline around each XFCE top-panel island while preserving real XFCE widgets, XEmbed plugins, global menus, tray icons, and click targets.

The active stable configuration is the commit before the temporary experiments in this document. It intentionally keeps the current one-pixel-visible outline rather than applying an unverified workaround.

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

The remaining navy is conclusively owned by the appmenu wrapper X window, not by the panel's internal child box. In a live VM, temporarily unmapping the visible `289×34` appmenu wrapper changed the same probe to:

```text
x=100,y=23 = #b75681
x=100,y=24 = #b75681
x=100,y=40 = #0e1624
x=100,y=57 = #b75681
x=100,y=58 = #b75681
```

Remapping the wrapper immediately restored `#131c2b` at `y=24` and `y=57` plus the appmenu content. The panel is already painting the desired two-pixel rose border and exact navy body beneath the wrapper.

There is no `_NET_WM_WINDOW_OPACITY` property on the panel or wrapper windows. A temporary `GTK_THEME=Adwaita` probe was inherited by the wrapper but left the navy unchanged; it is not ordinary active Adwaita-dark theme fill.

Right-island ownership is split:

```text
power:  panel GtkSocket 34×34 @ (971,24)
        └── wrapper-2.0 34×34 @ (971,24)

status: panel GtkSocket 35×34 @ (753,24)
        └── wrapper-2.0 35×34 @ (753,24)
            └── snixembed 22×22 @ (759,30)
```

Unmapping the power `wrapper-2.0` revealed rose at its inner rows, so the power overlap is directly owned by the wrapper. Unmapping only the status wrapper left navy because its panel-process `GtkSocket` remained mapped. Unmapping that socket then revealed `#b75681` at `y=24` and `y=57` and exact parent fill `#0e1624` at `y=40`. Status therefore has two potential painters: its wrapper and its socket.

Representative screenshots:

- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-baseline-20260819-172519.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-unmap2-20260819-172542.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-remap2-20260819-172545.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-q2B-20260819-182024.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-q2green-20260819-182523.png`

## Tested CSS approaches

### Wrapper and descendant resets

The configuration targeted `#XfcePanelWindowWrapper` and descendants with transparent backgrounds, no borders, and no shadows. This can remove the appmenu's visible dark-gray `#353535` fill, but it does not restore the second rose border row. Underlying navy remains.

### Q1: root `background-image` attribution

The earlier claim that root `background-image: none` made appmenu text disappear was false. It came from a multi-variable screenshot and was not isolated.

Four fresh-VM states all launched a focused terminal, retained a live mapped `289×34` appmenu wrapper, showed its `File Edit View Terminal Tabs Help` labels, and had no CSS parse error in the user journal:

| State | Parent selector | Wrapper root rule | Evidence |
|---|---|---|---|
| A | `#XfcePanelWindow` | `background-color: transparent` | `qemu-xfce-q1A-20260819-180930.png` |
| B | `#XfcePanelWindow` | A plus `background-image: none` | `qemu-xfce-q1B-20260819-181210.png` |
| C | `.xfce4-panel.background` | none | `qemu-xfce-q1C-20260819-181453.png` |
| D | `.xfce4-panel.background` | B plus `window#...` and `plug#...` selectors | `qemu-xfce-q1D-20260819-181738.png` |

Therefore root `background-image: none` is not a demonstrated cause of missing appmenu text. The old screenshot must have involved an unrecorded state variable and cannot support a causal claim.

### Broad `.xfce4-panel` reset

A reset of `.xfce4-panel` was not a panel-internal-container selector. It also matched wrapper plugs, removed external-plugin visuals, and left the inner rows navy. It was reverted.

### Panel COLOR background with alpha zero

Setting a panel to XFCE `background-style=COLOR` with `background-rgba=rgba(0,0,0,0)` did send a transparent color through XFCE's wrapper path. However, XFCE's local background provider then displaced the CSS parent fill, making the island itself disappear. It was reverted.

### Light-theme probe

A temporary VM-only `GTK_THEME=Adwaita` was inherited by `wrapper-2.0`. The navy inner-row pixels remained `#131c2b`. The probe was reverted.

### Q2: navy-pixel attribution

State B row scans show `#131c2b` filling every uncovered pixel of each wrapper, not only edge rows. Appmenu's 289-pixel span is navy on all rows `24` through `57` except where glyphs occupy pixels; the 35-pixel status and 34-pixel power spans have the same pattern around their icon content. This is a wrapper-surface fill, not a narrow border artifact.

All inspected appmenu, status, power, and status-socket windows have a 32-bit TrueColor visual, zero border width, and no `_NET_WM_WINDOW_OPACITY`. Installed `xwininfo` has no `-winwa`/background-pixel option, and neither XFCE source nor installed Adwaita files contains a literal `#131c2b` or equivalent RGB constant. Thus an X-server background-pixel hypothesis remains plausible but unproven.

The CSS-reach probe changed the wrapper root `background-color` to `#00ff00`; external-wrapper content no longer rendered in the resulting capture (`qemu-xfce-q2green-20260819-182523.png`). This proves root styling materially affects wrapper rendering, but does not identify the rendering path or the navy painter.

### `!important`

This GTK3 build logged parse errors for attempted declarations containing `!important`, including `Junk at end of value for background`. No persistent configuration uses it. GTK's CSS overview documents selectors, `rgba`, and `transparent`, but does not include `!important` in its declaration grammar: https://docs.gtk.org/gtk3/css-overview.html.

## Current conclusion

The panel is correct beneath external windows. Appmenu and power wrapper X windows own their overlap; status has both a wrapper and a panel-process GtkSocket overlap. All occupy the second border row because XFCE allocates them one pixel inside the panel.

We have not yet identified the exact producer of the wrapper's `#131c2b` surface fill. Do not claim that it is a theme constant, a panel internal child box, or a CSS image effect. Fix-route choice remains deferred.

## Deliberately not implemented

The following would be technical escape routes, but require explicit user approval before any implementation:

1. **XFCE panel source override:** reserve the full CSS border width when allocating the internal child and external-wrapper socket.
2. **XShape helper:** clip only a wrapper's visual perimeter while retaining its full input region.
3. **GTK module or appmenu resource override:** inject a high-priority, wrapper-process-specific style provider.

No source patch, helper, overlay painter, Picom fork, or pre-rendered corner asset was added.

## Reproduction and validation

The configuration source of truth is `readme.org`; `configuration.nix` is tangled output.

```sh
cd /home/mpontus/projects/nixpkgs
emacs --batch readme.org --eval "(require 'org)" --eval '(org-babel-tangle)'
nix-instantiate --parse configuration.nix
nixos-rebuild build-vm --flake .#nixos
```

Use a fresh qcow2 image, open a terminal to populate the global appmenu, capture the root window, and inspect `x=100` at rows `23`, `24`, `57`, and `58`.
