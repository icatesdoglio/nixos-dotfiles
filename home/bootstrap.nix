{ lib, ... }:

{
  home = {
    username = lib.mkDefault "ian";
    homeDirectory = lib.mkDefault "/home/ian";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}

