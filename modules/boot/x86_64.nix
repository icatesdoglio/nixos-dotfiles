{ config, lib, pkgs, ... }:

lib.mkIf (config.my.host.platform == "x86_64") {
  assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
      message = "x86_64 platform requires x86_64-linux";
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}

