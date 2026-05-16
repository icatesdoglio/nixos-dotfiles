{
  lib,
  config,
  pkgs,
  hyprland,
  bemenu,
  ...
}: let
  cfg = config.my.hm.desktop.hyprland;
in {
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
      [
        pkgs.foot
        pkgs.wofi
        pkgs.hyprpaper
        pkgs.cliphist
        pkgs.wl-clipboard
        pkgs.nushell
        pkgs.pavucontrol
        pkgs.apple-cursor
        bemenu.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.brightnessctl
        pkgs.swaynotificationcenter
        pkgs.libnotify
      ]
      ++ lib.optional cfg.withWaybar pkgs.waybar;

    home.file =
      {
        ".config/hypr" = {
          source = ../../config/hypr;
          force = true;
        };
        # Stable symlink so config/hypr/.luarc.json can reference ../hypr-stubs
        ".config/hypr-stubs".source =
          "${hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/share/hypr/stubs";
        ".config/swaync" = {
          source = ../../config/swaync;
          force = true;
        };
      }
      // lib.optionalAttrs cfg.withWaybar {
        ".config/waybar" = {
          source = ../../config/waybar;
          force = true;
        };
      };

    home.sessionVariables = {
      NIX_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";

      XCURSOR_THEME = "macOS";
      XCURSOR_SIZE = "24";

      HYPRCURSOR_THEME = "macOS";
      HYPRCURSOR_SIZE = "24";
    };
  };
}
