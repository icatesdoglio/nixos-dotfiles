{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
  ];


  networking = {
    hostName = "ServeMato";

    useDHCP = false;

    interfaces.eth0.ipv4.addresses = [
    {
      address = "192.168.0.30";
      prefixLength = 24;
    }
    ];

    defaultGateway = "192.168.0.1";

    nameservers = [
      "192.168.0.1"
        "1.1.1.1"
    ];
    firewall = {
      allowedUDPPorts = [ 51820 ];
      interfaces.wg0 = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 22 53 80 ];
      };
    };

    wireguard.interfaces.wg0 = {
      ips = [ "10.100.0.1/24" ];
      listenPort = 51820;
      privateKeyFile = "/etc/wireguard/server.key";



      peers = [
# Desktop
      {
        publicKey = "E3J+BJ2f+6VyLY8JB7ypzSOXdQsB66T/nr7mdcP4yxc=";
        allowedIPs = [ "10.100.0.2/32" ];
      }
# Mac-Mini
      {
        publicKey = "GXxa4bsYmIeLdvnznaNiX8kzOwfjoRCJTMG3uUrFCXk=";
        allowedIPs = [ "10.100.0.3/32" ];
      }
      ];
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
  ];

  boot.loader.raspberryPi = {
    enable = true;
    bootloader = "kernel";
  };

  hardware.raspberry-pi.extra-config = ''
    [all]
    initramfs initrd followkernel
    dtparam=nvme
    dtparam=pciex1_gen=3
    pcie_probe=1
  '';

  # reduce NVMe wear
  zramSwap.enable = true;

  services = {


    unbound = {
      enable = true;

      settings = {
        server = {
# Listen on WireGuard + localhost
          interface = [
            "127.0.0.1"
              "10.100.0.1"
          ];

          access-control = [
            "127.0.0.0/8 allow"
              "10.100.0.0/24 allow"
          ];

          do-ip6 = false;
          hide-identity = true;
          hide-version = true;

# Performance / sanity
          prefetch = true;
          cache-min-ttl = 60;
          cache-max-ttl = 86400;
        };

        forward-zone = [
        {
          name = ".";
          forward-addr = [
            "1.1.1.1"
              "8.8.8.8"
          ];
        }
        ];
      };
    };
    cloudflared = {
      enable = true; 
    };
    openssh.listenAddresses = [
    {
      addr = "10.100.0.1";
      port = 22;
        }
      ];
    nextcloud = {
      enable = true;

      hostName = "localhost";
      https = false;
      
      package = pkgs.nextcloud32;

      datadir = "/mnt/nc-data";

      config = {
        adminuser = "admin";
        adminpassFile = "/etc/nextcloud-admin-pass";
        dbtype = "pgsql";
      };

      database.createLocally = true;

    };

    postgresql.enable = true;
    redis.servers.nextcloud.enable = true;

  };


  nix.settings = {
    substituters = [
      "ssh-ng://ian@gp-linux"
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "desktop-cache:FhWK5ojANXSQA7s6/8bTZNHe59vo87rTCz8oD5aoIo8="
    ];

    trusted-users = [ "root" "ian" ];
  };

  system.stateVersion = "26.05";
}

# vim: ts=2 sts=2 sw=2 et
