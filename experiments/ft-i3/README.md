# Tint2 and i3 experiment

This branch preserves the VM-only four-island Tint2 prototype for a possible future migration from XFCE Panel and XMonad to Tint2 and i3.

## Tested state

- XMonad remained the window manager.
- XFCE Panel was stopped and replaced by four Tint2 instances.
- `xfdesktop`, `xfsettingsd`, XFCE Power Manager, XFCE Notifyd, Picom, NetworkManager applet, and snixembed remained in use.
- Fresh VM resolution: 1280×800.
- All islands were 36px high with 8px top/outer margins.
- Launcher, clock, system tray, volume action, and logout action rendered.
- `Super+Q` restarted XMonad without duplicating Tint2 instances.
- XFCE desktop icons remained hidden and the native wallpaper gallery remained available.

The captured result is `tint2-small.png`.

## Known adjustment

The right status island used a 60px right margin and rendered an 11px gap before the power island. Set its margin to 65px for the intended 16px gap.

## Next experiment

1. Integrate the Tint2 module through `readme.org` rather than VM-only imports.
2. Replace temporary XMonad startup commands with a user service.
3. Validate tray, volume, battery, notifications, app launcher, logout, multiple windows, and multiple monitors.
4. Once Tint2 is stable under XMonad, replace only the window manager with i3 and compare behavior.
