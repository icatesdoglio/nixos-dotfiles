{ lib, config, pkgs, dotfiles, ... }:

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
        source = dotfiles + "/config/nvim";
        force = true;
    };

  };
}

