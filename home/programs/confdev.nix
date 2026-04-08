{
  lib,
  config,
  pkgs,
  inputs,
  confdev,
  ...
}: {
  options.my.hm.programs.confdev.enable =
    lib.mkEnableOption "Enable confdev binary + marker file";

  config = lib.mkIf config.my.hm.programs.confdev.enable {
    # 1) Install your binary
    home.packages = [
      confdev.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # 2) Create the dummy marker file
    home.file.".config/confdev-mode.txt".text = ''
      confdev mode enabled
      This file exists so the confdev binary can detect mode
      and locate configuration in ~/.config/nvim.
      Managed by Nix Home Manager.
    '';
  };
}
