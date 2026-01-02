{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  my.host = {
    name = "ServeMato";
    role = "server";
    platform = "raspberry-pi";
  };


  hardware.raspberry-pi.extra-config = ''
    [all]
    initramfs initrd followkernel
    dtparam=nvme
    dtparam=pciex1_gen=3
    pcie_probe=1
  '';

  
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/32" ];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/server.key";

    peers = [
      { # Desktop
        publicKey = "E3J+BJ2f+6VyLY8JB7ypzSOXdQsB66T/nr7mdcP4yxc=";
        allowedIPs = [ "10.100.0.2/32" ];
      }
      { # Mac Mini
        publicKey = "GXxa4bsYmIeLdvnznaNiX8kzOwfjoRCJTMG3uUrFCXk=";
        allowedIPs = [ "10.100.0.3/32" ];
      }
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
  ];

  my.roles.edge = {
      enable = true;
      vpnSubnet = "10.200.0.0/24";
      useCloudflaredDNS = false;
  };


  zramSwap.enable = true;

  #### Static networking
  my.networking.static = {
    enable = true;
    interface = "eth0";
    address = "192.168.0.30";
    gateway = "192.168.0.1";
    nameservers = [ "192.168.0.1" "1.1.1.1" ];
  };

  nix.settings = {
      substituters = [
          "ssh-ng://ian@gp-linux"
              "https://cache.nixos.org"
      ];

      trusted-public-keys = [
          "desktop-cache:FhWK5ojANXSQA7s6/8bTZNHe59vo87rTCz8oD5aoIo8="
      ];
  };

  system.stateVersion = "26.05";
}

