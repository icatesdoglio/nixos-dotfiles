{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.desktop.plasma;
in {
  options.my.desktop.plasma.enable =
    lib.mkEnableOption "Enable KDE Plasma desktop";

  config = lib.mkIf cfg.enable {
    # Plasma 6 (preferred)
    services.desktopManager.plasma6.enable = true;

    # Wayland / Qt sanity
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };

    # Required for KDE auth dialogs
    security.polkit.enable = true;

    # Minimal system-wide KDE tools only
    environment.systemPackages = with pkgs; [
      kdePackages.konsole
      kdePackages.dolphin
      kdePackages.kate
      kdePackages.okular
      kdePackages.ark
    ];
  };
}
