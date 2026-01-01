{ lib, config, pkgs, ... }:

let
  cfg = config.my.hm.desktop.hyprland;
in
{
  options.my.hm.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland user configuration";

    withWaybar = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Waybar configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ pkgs.foot pkgs.wofi pkgs.hyprpaper pkgs.cliphist pkgs.wl-clipboard ]
      ++ lib.optional cfg.withWaybar pkgs.waybar;

    home.file = {
      ".config/hypr" = {
        source = ../../config/hypr;
        recursive = true;
        force = true;
      };
    } // lib.optionalAttrs cfg.withWaybar {
      ".config/waybar" = {
        source = ../../config/waybar;
        recursive = true;
        force = true;
      };
    };

    home.sessionVariables = {
      NIX_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";

      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";

      HYPRCURSOR_THEME = "Bibata-Modern-Ice";
      HYPRCURSOR_SIZE = "24";
    };
  };
}

