{ pkgs, lib, config, ... }:

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

  /******
    SOPS 
   *****/
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets = {
      "wg/surfshark/servemato" = {
          sopsFile = ../../secrets/wireguard.yaml;
          format = "yaml";
          path = "/etc/wireguard/wg-surf.key";
          owner = "root";
          group = "root";
          mode = "0440";
      };
      "wg/lan/servemato" = {
          sopsFile = ../../secrets/wireguard.yaml;
          format = "yaml";
          path = "/etc/wireguard/wg0.key";
          owner = "root";
          group = "root";
          mode = "0400";
      };
      "cloudflare/api_key" = {
          sopsFile = ../../secrets/cloudflare.yaml;
          format = "yaml";
          path = "/run/secrets/cloudflare-api-token";
          owner = "root";
          group = "root";
          mode = "0400";
      };
      "qbtPassword-encrypted" = {
          sopsFile = ../../secrets/qbt.yaml;
          format = "yaml";
          path = "/run/secrets/qbtPassword";
          owner = "qbit";
          group = "qbit";
          mode = "0400";
      };
  };

  environment.systemPackages = with pkgs; [ age sops ssh-to-age iproute2 ];

  users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
  ];

  /**********************************
    Edge Roll: VPN start & CloudFlare
   **********************************/
  my.roles.edge = {
    enable = true;
    vpnSubnet = "10.100.0.0/24";
    listenPort = 51820;         
    useCloudflaredDNS = false;  
    interface = "wg0";          
  };

  /* Static Networking Setup */
  my.networking.static = {
    enable = true;
    interface = "eth0";
    address = "192.168.0.30";
    gateway = "192.168.0.1";
    nameservers = [ "127.0.0.1" ];
  };
  my.networking.ipv6.method = "ignore";

  /**********************************
    PiHole and DSN resolution
   ***********************************/
  my.networking.unbound.enable = true;
  my.networking.pihole.enable = true;
  networking.firewall.allowedUDPPorts = [ 
      51820 # Wireguard
  ];
  networking.firewall.interfaces.wg0.allowedUDPPorts = [ 
      53      # DNS
      51820   # Wireguard
      51821   # Torrent port (UDP, DHT)
  ];
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 
      53      # DNS
      3000    # Home Page
      8081    # Web UI
      51821   # Torrent port (TCP)
  ];
  networking.firewall.interfaces."ca-van".allowedUDPPorts = [ 
      51821   # Torrent port (UDP, DHT)
  ];
  networking.firewall.interfaces."ca-van".allowedTCPPorts = [ 
      51821   # Torrent port (TCP)
  ];

  /*************
    VPN Settings
   *************/
  my.wireguard = {
      enable = true;

      /* Local */
      interfaces.wg0 = {
          mode = "server";
          interface = "wg0";
          listenPort = 51820;
          privateKeyFile = config.sops.secrets."wg/lan/servemato".path;
          address = "10.100.0.1/24";

          peers = {
              desktop = {
                  publicKey = "E3J+BJ2f+6VyLY8JB7ypzSOXdQsB66T/nr7mdcP4yxc=";
                  allowedIPs = [ "10.100.0.2/32" ];
                  persistentKeepalive = 25;
              };

              macmini = {
                  publicKey = "GXxa4bsYmIeLdvnznaNiX8kzOwfjoRCJTMG3uUrFCXk=";
                  allowedIPs = [ "10.100.0.3/32" ];
                  persistentKeepalive = 25;
              };

              iphone = {
                  publicKey = "hlZRXkdEdoHLpigkr3cP23X2qu89tf1Lj3hUbeMtGAw=";
                  allowedIPs = [ "10.100.0.4/32" ];
                  persistentKeepalive = 25;
              };

              archlaptop = {
                  publicKey = "mx/c3oFZwTQ824bA4kXPyr+CU0qVLO28imgENyEZgUU=";
                  allowedIPs = [ "10.100.0.5/32" ];
                  persistentKeepalive = 25;
              };
              framework = {
                  publicKey = "8A7L4okGuJSPtHIHxVNcTT18iGKr50Ipz18G9LAQKgE=";
                  allowedIPs = [ "10.100.0.6/32" ];
                  persistentKeepalive = 25;

              };
          };
      };
  };

  networking.wireguard.interfaces.ca-van = {
      ips = [ "10.14.0.2/16" ];

      privateKeyFile = config.sops.secrets."wg/surfshark/servemato".path;

      peers = [{
          publicKey = "o4HezxSsbNqJFJZj+VBw/QXFLpfNo7PZu8xe7H2hTw0=";
          endpoint = "ca-van.prod.surfshark.com:51820";
          allowedIPs = [ "0.0.0.0/0" ];
          persistentKeepalive = 25;
      }];
  };


  /*** ensure domain in cloudflare has correct configuration" ***/
  services.cloudflare-dyndns = {
      enable = true;
      apiTokenFile = config.sops.secrets."cloudflare/api_key".path;
      domains = [ "home.iancd.net" ];
      ipv4 = true;
      ipv6 = false;
      proxied = false;
  };

  /*********************
   *** SERVER CONFIG ***
   *********************/

  /* landing page */
  services.homepage-dashboard = {
      enable = true;

      listenPort = 3000;

      settings = {
          title = "ServeMato";
          theme = "dark";
          color = "slate";
      };
  };




  services.qbittorrent = {
      enable = true;
      user = "qbit";
      group = "qbit";

      webuiPort = 8081;
      torrentingPort = 51821;

      openFirewall = false; # More restrictive setup

          serverConfig = {
              /* Download paths */
              Downloads.SavePath = "/mnt/data/torrents";
              Downloads.TempPath = "/mnt/data/torrents/incomplete";
              Downloads.TempPathEnabled = true;

              Preferences.WebUI.Username = "admin"; 
              Preferences.WebUI.Password_PBKDF2 = {
                  _secret = config.sops.secrets.qbtPassword-encrypted.path;
              };
              /* Security / sanity */
              Preferences.WebUI.LocalHostAuth = false;
              Preferences.WebUI.AuthSubnetWhitelistEnabled = true;
              Preferences.WebUI.AuthSubnetWhitelist = "10.100.0.0/24";

              /* Optional: don’t expose UPnP */
              Preferences.Connection.UPnP = false;
          };
  };

  environment.etc."iproute2/rt_tables".text = ''
      200 vpn
      '';

  systemd.services.qbittorrent-policy-routing = {
      description = "Policy routing for qBittorrent over WireGuard";
      wantedBy = [ "multi-user.target" ];
      after = [
          "network-online.target"
              "wireguard-ca-van.service"
              "sys-subsystem-net-devices-ca-van.device"
      ];
      wants = [ 
          "network-online.target" 
          "sys-subsystem-net-devices-ca-van.device"
      ];

      serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;

          execStop = let
              qbitUid = toString config.users.users.qbit.uid;
          ip = "${pkgs.iproute2}/bin/ip";
          in ''
              ${ip} rule del to 10.100.0.0/24 lookup main || true
              ${ip} rule del uidrange ${qbitUid}-${qbitUid} lookup vpn || true
              '';
      };

      script = let
          qbitUid = toString config.users.users.qbit.uid;
      ip = "${pkgs.iproute2}/bin/ip";
      in ''
# Ensure wg admin traffic never goes to VPN
          ${ip} rule add to 10.100.0.0/24 lookup main priority 9000 || true

# Force qbit traffic to VPN
          ${ip} route replace default dev ca-van table vpn
          ${ip} rule add uidrange ${qbitUid}-${qbitUid} lookup vpn priority 10000 || true

          ${ip} route flush cache
          '';

  };

  zramSwap.enable = true;


   /***********
   Substituters 
   ************/
  nix.settings = {
      substituters = [
          "ssh-ng://ian@10.100.0.2"
          "ssh-ng://ian@gp-linux"
          "ssh-ng://ian@10.100.0.6"
          "ssh-ng://ian@framework"
              "https://cache.nixos.org"
      ];

      trusted-public-keys = [
          "desktop-cache:FhWK5ojANXSQA7s6/8bTZNHe59vo87rTCz8oD5aoIo8="
      ];
  };

  services.openssh.enable = true;

  system.stateVersion = "26.05";
}

