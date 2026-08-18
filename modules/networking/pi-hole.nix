{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.networking.pihole;
  dnsReservationLines =
    lib.mapAttrsToList
    (name: ip: "host-record=${name},${ip}")
    cfg.dnsReservations;

  wildcardLines =
    map (domain: "address=/.${domain}/${cfg.hostIP}")
    cfg.wildcardDomains;
in {
  options.my.networking.pihole = {
    enable = lib.mkEnableOption "Pi-hole";

    localDomain = lib.mkOption {
      type = lib.types.str;
      default = "lan";
      description = "Local DNS domain served by Pi-hole.";
    };

    hostIP = lib.mkOption {
      type = lib.types.str;
      example = "10.100.0.1";
      description = "IP address Pi-hole should resolve local domains to.";
    };

    dnsReservations = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Static DNS records served by Pi-hole.";
    };

    wildcardDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["servemato.lan"];
      description = ''
        Domains that should resolve all subdomains to this host.
        Requires dnsmasq wildcard rules.
      '';
    };

    listenAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["127.0.0.1"];
      description = ''
        Addresses dnsmasq should bind to. Setting this adds bind-interfaces
        to prevent dnsmasq from grabbing 0.0.0.0:53 (which conflicts with
        podman's aardvark-dns on container bridge IPs).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.piHolePassword = {
      sopsFile = ../../secrets/pihole-secrets.yaml;
      owner = "pihole";
      group = "pihole";
      mode = "0400";
    };

    users.users.pihole = {
      isSystemUser = true;
      group = "pihole";
      home = "/var/lib/pihole";
    };

    users.groups.pihole = {};

    services.pihole-ftl = {
      enable = true;
      openFirewallDNS = true;
      openFirewallWebserver = true;
      lists = [
        {url = "https://abp.oisd.nl/basic/";}
        {url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";}
      ];

      settings = {
        dns = {
          upstreams = ["127.0.0.1#5335"];

          domainNeeded = true;
          expandHosts = true;
        };

        dhcp = {
          active = false;
        };

        misc.dnsmasq_lines =
          [
            "expand-hosts"
            "domain-needed"
            "bogus-priv"
            "domain=${cfg.localDomain}"
            "bind-interfaces"
          ]
          ++ map (addr: "listen-address=${addr}") cfg.listenAddresses
          ++ dnsReservationLines
          ++ wildcardLines;
      };
    };

    services.pihole-web = {
      enable = true;
      ports = [8080];
    };

    environment.systemPackages = with pkgs; [dig];
  };
}
