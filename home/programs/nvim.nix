{ lib, config, pkgs, ... }:

let
  cfg = config.my.hm.programs.neovim;
in
{
  options.my.hm.programs.neovim.enable =
    lib.mkEnableOption "Neovim";

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };

    home.packages = with pkgs; [ tree-sitter ];

    home.file.".config/nvim" = {
      source = ../../config/nvim;
      recursive = true;
      force = true;
    };
  };
}

