{ lib, config, pkgs, ... }:

let
  cfg = config.my.hm.programs.river;
in
{
  options.my.hm.programs.river.enable =
    lib.mkEnableOption "River user configuration";

  config = lib.mkIf cfg.enable {

    # User-space tools River configs typically rely on
    home.packages = with pkgs; [
      wl-clipboard
      mako
      swaybg
    ];

    # Own the River config directory, just like nvim
    home.file.".config/river" = {
      source = ../../config/river;
      force = true;
    };
    home.sessionPath = [
      "$HOME/.local/bin"
    ];


  };
}
