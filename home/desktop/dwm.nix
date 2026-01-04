{ lib, config, pkgs, suckless, ... }:

let
  cfg = config.my.hm.desktop.dwm;
in
{
  options.my.hm.desktop.dwm.enable = lib.mkEnableOption "Enable dwm (suckless window manager)";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      xclip
      feh
      picom
      pywal16
    ] ++ [
      suckless.packages.${pkgs.system}.dwm
      suckless.packages.${pkgs.system}.dmenu
      suckless.packages.${pkgs.system}.st
      suckless.packages.${pkgs.system}.dwmblocks
    ];
  };
}
