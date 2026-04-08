{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption types;

  cfg = config.my.desktop;
  nvidiaEnabled = config.my.hardware.nvidia.enable or false;

  # make sure to register new desktops with the correct environment
  anyWaylandEnabled = cfg.hyprland.enable || cfg.river.enable || cfg.plasma.enable;
  anyX11Enabled = cfg.dwm.enable;
in {
  imports = [
    ./fonts.nix
    ./audio.nix
    ./hyprland.nix
    ./dwm.nix
    ./river.nix
    ./plasma.nix
  ];
  options.my.desktop = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Desktop environment aggregator";
    };

    useDisplayManager = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to use a display manager (GDM/SDDM/etc)";
    };
  };

  config = mkMerge [
    # Shared desktop defaults
    (mkIf cfg.enable {
      my.desktop.audio.enable = true;
      my.desktop.fonts.enable = true;
    })

    # Shared Wayland plumbing (DESKTOP-AGNOSTIC)
    (mkIf (cfg.enable && anyWaylandEnabled) {
      xdg.portal.enable = true;
      xdg.portal.extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-wlr
      ];

      xdg.portal.config = {
        common.default = "hyprland";
        hyprland.default = "hyprland";
        river.default = "wlr";
      };

      environment.systemPackages = with pkgs; [
        wl-clipboard
        wayland-utils
      ];
    })

    # Shared X11 plumbing
    (mkIf (cfg.enable && anyX11Enabled) {
      services.xserver.enable = true;
    })

    # X11 without a display manager (startx)
    (mkIf (cfg.enable && anyX11Enabled && !cfg.useDisplayManager) {
      services.xserver.displayManager.startx.enable = true;

      # Explicitly disable common DMs
      services.displayManager.gdm.enable = false;
      services.displayManager.sddm.enable = false;
      services.xserver.displayManager.lightdm.enable = false;
    })

    # X11 WITH a display manager (future-proof)
    (mkIf (cfg.enable && anyX11Enabled && cfg.useDisplayManager) {
      services.displayManager.sddm.enable = true;
    })

    # NVIDIA-specific Wayland fixes
    (mkIf (cfg.enable && anyWaylandEnabled && nvidiaEnabled) {
      environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
    })
  ];
}
# vim: ts=2 sts=2 sw=2 et

