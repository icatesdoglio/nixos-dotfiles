{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkMerge types mkOption;
  cfg = config.my.desktop.wayland;

  anyWaylandEnabled =
    cfg.hyprland.enable
    || cfg.sway.enable
    || cfg.weston.enable;
in {
  options.my.desktop.wayland = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Manage Wayland desktop dependencies";
    };

    hyprland.enable = mkEnableOption "Enable Hyprland (Wayland)";
    sway.enable = mkEnableOption "Enable Sway (Wayland)";
    weston.enable = mkEnableOption "Enable Weston (Wayland)";
  };

  config = mkMerge [
    # Shared Wayland plumbing
    (mkIf (cfg.enable && anyWaylandEnabled) {
      programs.xwayland.enable = true;

      environment.systemPackages = with pkgs; [
        wayland-utils
        wl-clipboard
      ];

      xdg.portal.enable = true;
      xdg.portal.extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    })

    # Individual compositors
    (mkIf cfg.hyprland.enable {
      programs.hyprland.enable = true;
    })

    (mkIf cfg.sway.enable {
      programs.sway.enable = true;
    })

    (mkIf cfg.weston.enable {
      services.weston.enable = true;
    })
  ];
}
