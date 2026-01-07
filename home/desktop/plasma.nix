{ config, pkgs, lib, ... }:

let
  cfg = config.my.hm.desktop.plasma;
in
{
  options.my.hm.desktop.plasma.enable =
    lib.mkEnableOption "Enable KDE Plasma user config";

  config = lib.mkIf cfg.enable {

    # KDE writes to ~/.config, so we manage selectively
    home.packages = with pkgs; [
      kdePackages.kdeconnect-kde
      kdePackages.kcalc
      kdePackages.kcolorchooser
    ];

    # Fonts (this is where SF Pro / Inter will live later)
    fonts.fontconfig.enable = true;

    # Plasma config files (safe to manage declaratively)
    xdg.configFile = {

      # Disable desktop icons (macOS style)
      "plasma-org.kde.plasma.desktop-appletsrc".text = ''
        [Containments][1][General]
        showDesktopIcons=false
      '';

      # Reduce animation noise
      "kwinrc".text = ''
        [Compositing]
        AnimationSpeed=3
      '';
    };

    xdg.configFile."kwinrc".force = true;

    # Keep KDE from spawning unwanted defaults
    home.sessionVariables = {
      KDE_NO_GLOBAL_MENU = "false";
    };
  };
}

