{
  config,
  lib,
  suckless,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  options.my.hm.desktop.dwm.enable =
    lib.mkEnableOption "Enable dwm";

  config = lib.mkIf config.my.hm.desktop.dwm.enable {
    home.packages = [
      suckless.packages.${system}.dwm
      suckless.packages.${system}.dmenu
      suckless.packages.${system}.st
      suckless.packages.${system}.dwmblocks
    ];
  };
}
