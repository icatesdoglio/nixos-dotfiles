{
  lib,
  config,
  pkgs,
  dotfiles,
  ...
}: let
  cfg = config.my.hm.programs.neovim;
in {
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
        pyright
        marksman
        lua-language-server
        postgresql
        databricks-cli
        (databricks-sql-cli.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            substituteInPlace $out/lib/python*/site-packages/dbsqlcli/sqlexecute.py \
              --replace-fail '_user_agent_entry=' 'user_agent_entry='
          '';
        }))
      ];
      plugins = with pkgs.vimPlugins; [
        nvim-treesitter
        telescope-nvim
        plenary-nvim
        blink-cmp
        blink-cmp-conventional-commits
        oil-nvim
        harpoon2
        friendly-snippets
        vim-fugitive
        vim-slime
        vim-dadbod
        vim-dadbod-ui
        vim-dadbod-completion
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
