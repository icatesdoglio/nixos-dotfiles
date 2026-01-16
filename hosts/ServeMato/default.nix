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
  };

  environment.systemPackages = with pkgs; [ age sops ssh-to-age ];

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

  /**********************************
    PiHole and DSN resolution
   ***********************************/
  my.networking.unbound.enable = true;
  my.networking.pihole.enable = true;
  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.interfaces.wg0.allowedUDPPorts = [ 53 51820 ];
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 53 ];

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

  /*** ensure domain in cloudflare has correct configuration" ***/
  services.cloudflare-dyndns = {
      enable = true;
      package = pkgs.cloudflare-ddns;
      apiTokenFile = config.sops.secrets."cloudflare/api_key".path;
      domains = [ "iancd.net" ];
      ipv4 = true;
      ipv6 = false;
  };

  services.qbittorent = {
      enable = true;
      openWebUI = true;
      dataDir = "/mnt/data/torrents";
      user = "qbittorent";
      networkNamespace = "vpn";
      preStart = ''
          ip netns exec vpn iptables -P OUTPUT DROP
          ip netns exec vpn iptables -A OUTPUT -o ca-van -j ACCEPT
      '';
  };

  systemd.services."ca-van".bindsTo = [ "network.target" ];
  systemd.services."ca-van".after = [ "network.target" ];
  systemd.services."ca-van".before = [ "qbittorrent.service" ];
  systemd.services."ca-van".networkNamespace = "vpn";


  zramSwap.enable = true;


   /***********
   Substituters 
   ************/
  nix.settings = {
      substituters = [
          "ssh-ng://ian@10.100.0.2"
          "ssh-ng://ian@gp-linux" # Allow remote builds
              "https://cache.nixos.org"
      ];

      trusted-public-keys = [
          "desktop-cache:FhWK5ojANXSQA7s6/8bTZNHe59vo87rTCz8oD5aoIo8="
      ];
  };

  services.openssh.enable = true;

  system.stateVersion = "26.05";
}

