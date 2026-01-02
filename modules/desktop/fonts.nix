{ lib, config, pkgs, ... }:

let
  cfg = config.my.desktop.fonts;
in
{
  options.my.desktop.fonts = {
    enable = lib.mkEnableOption "desktop fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.inconsolata
        nerd-fonts.jetbrains-mono
      ];
    };
  };
}

