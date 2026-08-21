{ pkgs, ... }:
let
  common = ''
    rounded = 12
    border_width = 2
    border_sides = TBLR
    background_color = #0e1624 100
    border_color = #b75681 100

    panel_monitor = 1
    panel_size = 100% 36
    panel_shrink = 1
    panel_margin = 8 8
    panel_padding = 8 0 6
    panel_background_id = 1
    panel_layer = top
    strut_policy = none
    mouse_effects = 0
    font_shadow = 0

    tooltip_show_timeout = 0.5
    tooltip_hide_timeout = 0.2
    tooltip_padding = 8 4
    tooltip_background_id = 1
    tooltip_font = JetBrainsMono Nerd Font 10
    tooltip_font_color = #f4effa 100
  '';
in {
  environment.systemPackages = [ pkgs.tint2 ];

  home-manager.users.mpontus.xdg.configFile = {
    "tint2/left.conf".text = common + ''
      panel_position = top left horizontal
      panel_items = P
      button = new
      button_text = ☰
      button_tooltip = Applications
      button_font = JetBrainsMono Nerd Font Bold 15
      button_font_color = #f4effa 100
      button_padding = 5 0
      button_lclick_command = xfce4-appfinder
    '';

    "tint2/center.conf".text = common + ''
      panel_position = top center horizontal
      panel_items = C
      time1_format = %a %d %b  |  %I:%M %p
      time1_font = JetBrainsMono Nerd Font 10
      clock_font_color = #f4effa 100
      clock_padding = 8 0
      clock_tooltip = %A %d %B %Y
    '';

    "tint2/right.conf".text = common + ''
      panel_position = top right horizontal
      panel_margin = 60 8
      panel_items = SEB
      systray_padding = 2 0 3
      systray_icon_size = 20
      systray_monitor = 1
      execp = new
      execp_command = printf ''
      execp_interval = 0
      execp_font = JetBrainsMono Nerd Font 12
      execp_font_color = #f4effa 100
      execp_padding = 5 0
      execp_tooltip = Volume
      execp_lclick_command = pavucontrol
      battery_hide = 101
      bat1_format = %p
      bat1_font = JetBrainsMono Nerd Font 9
      battery_font_color = #f4effa 100
      battery_padding = 4 0
    '';

    "tint2/power.conf".text = common + ''
      panel_position = top right horizontal
      panel_items = P
      button = new
      button_text = ⏻
      button_tooltip = Log out
      button_font = JetBrainsMono Nerd Font Bold 14
      button_font_color = #f4effa 100
      button_padding = 5 0
      button_lclick_command = xfce4-session-logout
    '';
  };
}
