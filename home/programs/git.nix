{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.hm.programs.git;
in {
  options.my.hm.programs.git.enable =
    lib.mkEnableOption "Git user configuration";

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings.core.pager = "delta";
    };

    home.packages = with pkgs; [
      git
      gh
      github-copilot-cli
      codex
      delta
      azure-cli
    ];

    home.file.".config/git" = {
      source = ../../config/git;
      force = true;
    };
  };
}
