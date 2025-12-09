{ config, pkgs, modulesPath, ... }:

{
  ########################################
  # Base System Imports
  ########################################

  # Minimal profile (no GUI)
  imports = [
      (modulesPath + "/profiles/minimal.nix")
          (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  ########################################
  # Bootloader / Hardware
  ########################################

  # Pi 5 uses its own boot mechanism
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.binfmt.emulatedSystems = [];

  ########################################
  # Networking
  ########################################

  networking.hostName = "rpi5";

  # You can switch to systemd.network if you prefer
  networking.networkmanager.enable = true;

  ########################################
  # SSH Access
  ########################################

  services.openssh = {
    enable = true;
    settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
  ];

  ########################################
  # User Account
  ########################################

  users.users.ian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
    ];
  };

  ########################################
  # System Settings
  ########################################

  time.timeZone = "America/Los_Angeles";

  # Recommended for Pi — reduces SD wear
  zramSwap.enable = true;

  # Base packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    tmux
  ];

  # Required for using nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  ########################################
  # State Version
  ########################################

  system.stateVersion = "24.05";
}
