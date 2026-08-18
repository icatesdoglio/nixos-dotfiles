{
  lib,
  config,
  ...
}: let
  cfg = config.my.desktop.dwm;
in {
  options.my.desktop.dwm = {
    enable = lib.mkEnableOption "Enable dwm (X11 window manager)";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.displayManager.startx.enable = true;

    #services.xserver.windowManager.dwm.enable = true;

    # Common X11 niceties
    services.xserver.xkb = {
      layout = "us";
      options = "ctrl:swapcaps"; # example
    };
  };
}
