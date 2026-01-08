{ lib, config, pkgs, ... }:

let
  cfg = config.my.hm.programs.wezterm;
in
{
  options.my.hm.programs.wezterm.enable =
    lib.mkEnableOption "WezTerm";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ wezterm ];

    home.file.".config/wezterm" = {
      source = ../../config/wezterm;
      force = true;
    };
  };
}

