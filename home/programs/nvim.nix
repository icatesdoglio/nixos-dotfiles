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
            extraPackages = with pkgs; [
                ripgrep
                    tree-sitter 
                    fzf
                    fd
                    stylua
                    shfmt
                    shellcheck
                    alejandra
            ];
            plugins = with pkgs.vimPlugins; [
                nvim-treesitter
                    telescope-nvim
                    plenary-nvim
                    blink-cmp
                    blink-cmp-conventional-commits
                    oil-nvim
                    friendly-snippets
                    fugitive
            ];

            viAlias = true;
            vimAlias = true;

        };

        home.file.".config/nvim" = {
            source = dotfiles + "/config/nvim";
            force = true;
        };

    };
}

