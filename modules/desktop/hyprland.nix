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
