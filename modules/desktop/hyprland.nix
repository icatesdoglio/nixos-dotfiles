{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.desktop.hyprland;
in {
  options.my.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # Ensure XDG_CURRENT_DESKTOP is in the systemd user environment before
    # xdg-desktop-portal activates, so Flatpak apps (e.g. Zoom) get routed
    # to xdg-desktop-portal-hyprland for screensharing reliably.
    systemd.user.sessionVariables.XDG_CURRENT_DESKTOP = "Hyprland";

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs
      .hyprland
      .packages
      .${pkgs.stdenv.hostPlatform.system}
      .xdg-desktop-portal-hyprland;
    };

    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [
      foot
      waybar
      wezterm
      wofi
      hyprpaper
      cliphist
      wl-clipboard
    ];
  };
}
