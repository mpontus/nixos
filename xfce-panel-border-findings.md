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

Representative screenshots:

- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-baseline-20260819-172519.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-unmap2-20260819-172542.png`
- `/home/mpontus/Pictures/pi-screenshots/qemu-xfce-probe-remap2-20260819-172545.png`

## Tested CSS approaches

### Wrapper and descendant resets

The configuration targeted `#XfcePanelWindowWrapper` and descendants with transparent backgrounds, no borders, and no shadows. This can remove the appmenu's visible dark-gray `#353535` fill, but it does not restore the second rose border row. Underlying navy remains.

### Root-only transparent background

Targeting the named ARGB GtkPlug root with only `background-color: transparent` preserves icons and menu text. It still leaves navy on the inner border rows.

Adding `background-image: none` to the root produced a fully transparent-looking wrapper perimeter, but external plugin content disappeared. It is not acceptable because launcher, tray, appmenu, and power-plugin visuals must remain real and visible.

### Broad `.xfce4-panel` reset

A reset of `.xfce4-panel` was not a panel-internal-container selector. It also matched wrapper plugs, removed external-plugin visuals, and left the inner rows navy. It was reverted.

### Panel COLOR background with alpha zero

Setting a panel to XFCE `background-style=COLOR` with `background-rgba=rgba(0,0,0,0)` did send a transparent color through XFCE's wrapper path. However, XFCE's local background provider then displaced the CSS parent fill, making the island itself disappear. It was reverted.

### Light-theme probe

A temporary VM-only `GTK_THEME=Adwaita` was inherited by `wrapper-2.0`. The navy inner-row pixels remained `#131c2b`. The probe was reverted.

### `!important`

This GTK3 build logged parse errors for attempted declarations containing `!important`, for example:

```text
Junk at end of value for background
```

No persistent configuration uses `!important`.

## Current conclusion

The appmenu `wrapper-2.0` X window is the remaining navy painter. It occupies the second border row because XFCE allocates it one pixel inside the panel. The panel itself is correct beneath it.

Current user CSS cannot make that wrapper visually transparent without either leaving navy pixels or hiding plugin content. The remaining direct solutions are therefore allocation correction or visual clipping, not more panel-container CSS.

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
