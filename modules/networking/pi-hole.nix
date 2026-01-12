{ lib, config, sops-nix, pkgs, ... }:

let
cfg = config.my.networking.pihole;
in {
    options.my.networking.pihole = {
        enable = lib.mkEnableOption "Pi-hole";
    };

    config = lib.mkIf cfg.enable {
        sops.secrets.piHolePassword = {
            sopsFile = ../../secrets/pihole-secrets.yaml;
            owner = "pihole";
            group = "pihole";
            mode  = "0400";
        };

        users.users.pihole = {
            isSystemUser = true;
            group = "pihole";
            home  = "/var/lib/pihole";
        };

        users.groups.pihole = { };

        services.pihole-ftl = {
            enable = true;
            openFirewallDNS = true;
            openFirewallWebserver = true;
            lists = [
            { url = "https://abp.oisd.nl/basic/"; }
            { url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"; }
            ];

            settings = {
                dns = {
                    interface = "all";
                    listeningMode = "all";  # or "local" / "all"
                        upstreams = [ "127.0.0.1#5335" ];

                    domainNeeded = true;
                    expandHosts  = true;
                };

                dhcp = {
                    active = false;
                };

                misc.dnsmasq_lines = [
                    "expand-hosts"
                        "domain-needed"
                        "bogus-priv"
                        "domain=lan"
                        "address=/pi.hole/10.100.0.1"
                ];
            };
        };

        services.pihole-web = {
            enable = true;
            ports = [ 8080 ];
        };

        environment.systemPackages = with pkgs; [ dig ];
    };
}

