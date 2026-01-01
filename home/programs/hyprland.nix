{ lib, config, pkgs, ... }:

let
  cfg = config.my.hm.desktop.hyprland;
in
{
  ##############################
  # Options
  ##############################

  options.my.hm.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland user configuration";

    waybar.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Waybar configuration";
    };

    clipboard.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable wl-clipboard + cliphist";
    };

    terminal = lib.mkOption {
      type = lib.types.enum [ "foot" "wezterm" ];
      default = "foot";
      description = "Default terminal for Hyprland session";
    };
  };

  ##############################
  # Config
  ##############################

  config = lib.mkIf cfg.enable {

    #################################
    # Packages
    #################################

    home.packages =
      lib.optionals (cfg.terminal == "foot") [ pkgs.foot ]
      ++ lib.optionals cfg.waybar.enable [ pkgs.waybar ]
      ++ lib.optionals cfg.clipboard.enable [
        pkgs.wl-clipboard
        pkgs.cliphist
      ]
      ++ [
        pkgs.wofi
        pkgs.hyprpaper
      ];

    #################################
    # Dotfiles
    #################################

    home.file = {
      ".config/hypr" = {
        source = ../../config/hypr;
        recursive = true;
        force = true;
      };
    }
    // lib.optionalAttrs cfg.waybar.enable {
      ".config/waybar" = {
        source = ../../config/waybar;
        recursive = true;
        force = true;
      };
    };

    #################################
    # Session Environment
    #################################

    home.sessionVariables = {
      NIX_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";

      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";

      HYPRCURSOR_THEME = "Bibata-Modern-Ice";
      HYPRCURSOR_SIZE = "24";
    };

    #################################
    # Assertions
    #################################

    assertions = [
      {
        assertion = config.programs.home-manager.enable;
        message = "Hyprland HM module requires Home Manager to be enabled.";
      }
    ];
  };
}

