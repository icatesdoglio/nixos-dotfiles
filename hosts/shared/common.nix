{ config, pkgs, lib, ... }:

{
  time.timeZone = "America/Los_Angeles";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  #### Users
  users.users.ian = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO94PCjlZZQOajkBrVSLSNUrCXFjVeUOfYXJCZWJvxJO"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  environment.systemPackages = with pkgs; [
    vim git wget curl htop tmux gnupg
    tcpdump
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  virtualisation.docker.enable = true;
}
