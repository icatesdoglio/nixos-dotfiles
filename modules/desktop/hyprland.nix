{ lib, config, pkgs, ... }:

let
  cfg = config.my.desktop.hyprland;
in
{
  options.my.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop environment";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [
      foot waybar wezterm wofi hyprpaper
      cliphist wl-clipboard
    ];
  };
}

