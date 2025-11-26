{ config, pkgs, legacy, confdev, ... }:

{
  home.username = "ian";
  home.homeDirectory = "/home/ian";
  home.stateVersion = "25.05";

  # Dotfiles
  home.file.".config/hypr" = {
      source = ./config/hypr;
      force = true;
  };
  home.file.".config/waybar" = {
      source = ./config/waybar;
      force = true;
  };
  home.file.".config/git" = {
      source = ./config/git;
      force = true;
  };
  home.file.".config/wezterm" = {
      source = ./config/wezterm;
      force = true;
  };

  home.packages = with pkgs; [
      # Custom cli
      (confdev.packages.${system}.default)

      tree
          tree-sitter
          ripgrep
          uv

          # Python
          python313
          python3Packages.pip
          pyright

          # Rust (using rustup)
          rustup

          #  # Two R versions + R LSP
          R
          (pkgs.writeShellScriptBin "R42" ''
           exec ${legacy.rWrapper}/bin/R "$@"
           '')

          lua-language-server
  
          # Node (includes npm)
          nodejs
          pkgs.gcr


          gh delta nushell zoxide starship
          ];

  home.shellAliases = {
      nbc = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#main";
      hbc = "home-manager switch --flake ~/nixos-dotfiles#main";
  };

  home.sessionVariables = {
      GPG_TTY = "$TTY";
  };

  programs.neovim = {
      enable = true;
      extraPackages = with pkgs; [
          tree-sitter
      ];
  };

  programs.bash.enable = true;
  programs.git = {
      enable = true;
      extraConfig = { core.pager = "delta"; };
  };
}
