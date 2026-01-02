{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Filesystems discovered by nixos-generate-config / manual partitioning
  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-uuid/F063-F0CE";
    fsType = "vfat";
    options = [ "noatime" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/365dff42-d5be-41d1-a96f-a667c68ffb86";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  # No swap by default (Pi 5 uses zram)
  swapDevices = [ ];

  # Kernel modules automatically detected
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "usbhid"
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];

}
