{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge types mkOption;
  cfg = config.my.desktop.x11;

  anyXwmEnabled =
    cfg.dwm.enable
    || cfg.i3.enable
    || cfg.awesome.enable
    || cfg.xmonad.enable;

in
{
  options.my.desktop.x11 = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Master switch for managing X11 desktop dependencies.
        If true, enabling any configured X11 window manager will auto-enable services.xserver.
      '';
    };

    startx.enable = mkEnableOption "Enable startx (xinit) for launching X sessions";

    dwm.enable = mkEnableOption "Enable dwm (X11)";
    i3.enable = mkEnableOption "Enable i3 (X11)";
    awesome.enable = mkEnableOption "Enable awesome (X11)";
    xmonad.enable = mkEnableOption "Enable xmonad (X11)";
  };

  config = mkMerge [
    # Auto-enable Xorg when any X11 WM is enabled (and master switch is on).
    (mkIf (cfg.enable && anyXwmEnabled) {
      services.xserver.enable = true;

      # Optional but common: install some X utilities when you opt into X at all.
      environment.systemPackages = with pkgs; [
        xorg.xkill
        xorg.xrandr
        xorg.xsetroot
      ];
    })

    # startx support (only if Xorg is enabled)
    (mkIf (cfg.enable && anyXwmEnabled && cfg.startx.enable) {
      services.xserver.displayManager.startx.enable = true;
    })

    # Individual WMs
    (mkIf (cfg.enable && cfg.dwm.enable) {
      services.xserver.windowManager.dwm.enable = true;
    })

    (mkIf (cfg.enable && cfg.i3.enable) {
      services.xserver.windowManager.i3.enable = true;
    })

    (mkIf (cfg.enable && cfg.awesome.enable) {
      services.xserver.windowManager.awesome.enable = true;
    })

    (mkIf (cfg.enable && cfg.xmonad.enable) {
      services.xserver.windowManager.xmonad.enable = true;
    })
  ];
}

