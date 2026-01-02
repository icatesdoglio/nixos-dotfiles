{ config, lib, pkgs, ... }:

lib.mkIf (config.my.host.platform == "raspberry-pi") {

  ##########################################################################
  # Safety
  ##########################################################################

  assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.system == "aarch64-linux";
      message = "Raspberry Pi platform requires aarch64-linux";
    }
  ];
  ##########################################################################
  # Bootloader (nvmd-owned)
  ##########################################################################

  boot.loader.raspberryPi = {
    enable = true;
    bootloader = "kernel";
  };

  ##########################################################################
  # Firmware / device-tree tweaks
  ##########################################################################

  hardware.raspberry-pi.extra-config = ''
    [all]
    initramfs initrd followkernel

    dtparam=nvme
    dtparam=pciex1_gen=3
    pcie_probe=1
  '';

  ##########################################################################
  # Memory / swap defaults
  ##########################################################################

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}

