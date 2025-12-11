{ config, pkgs, legacy, confdev, ... }:

{
  home.username = "ian";
  home.homeDirectory = "/home/ian";
  home.stateVersion = "25.05";

  # Dotfiles
  home.file.".config/hypr" = {
      source = ../../config/hypr;
      force = true;
  };
  home.file.".config/waybar" = {
      source = ../../config/waybar;
      force = true;
  };
  home.file.".config/git" = {
      source = ../../config/git;
      force = true;
  };
  home.file.".config/wezterm" = {
      source = ../../config/wezterm;
      force = true;
  };

  home.packages = with pkgs; [
      # Custom cli
      (confdev.packages.${pkgs.system}.default)


      tree
          tree-sitter
          ripgrep

          # Python
          uv python313 python3Packages.pip pyright

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


          gh delta nushell zoxide starship jq htop

          bibata-cursors

          #testing
          prismlauncher # Im not sold on this
          ];

  home.shellAliases = {
    nbc = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#main-desktop";
    hbc = "home-manager switch --flake ~/nixos-dotfiles#main-desktop";
  };

home.sessionVariables = {
  GPG_TTY = "$TTY";
  XCURSOR_THEME = "Bibata-Modern-Ice";
  XCURSOR_SIZE = "24";

  # Optional, future-proof for hyprcursor animated themes
  HYPRCURSOR_THEME = "Bibata-Modern-Ice";
  HYPRCURSOR_SIZE = "24";
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
      settings = { core.pager = "delta"; };
  };

  programs.starship.enable = true;
  programs.zoxide.enable = true;
}

# vim: ts=2 sts=2 sw=2 et
