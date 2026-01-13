{ config, sops-nix, ... }:

{

    imports = [
        ./hardware-configuration.nix
    ];

    my.host = {
        name = "gp-linux";
        role = "desktop";
        platform = "x86_64";
    };

    /******
      SOPS 
     *****/
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";

    sops.secrets = {
        "wg/surfshark/gplinux" = {
            sopsFile = ../../secrets/wireguard.yaml;
            format = "yaml";
            path = "/etc/wireguard/wg-surf.key";
            owner = "root";
            group = "root";
            mode = "0400";
        };
        "wg/lan/gplinux" = {
            sopsFile = ../../secrets/wireguard.yaml;
            format = "yaml";
            path = "/etc/wireguard/wg0.key";
            owner = "root";
            group = "root";
            mode = "0400";
        };
    };

    /*************
      VPN Settings
     *************/
    my.wireguard = {
        enable = true;
        interfaces.wg0 = {
            mode = "client";
            interface = "wg0";
            privateKeyFile = config.sops.secrets."wg/lan/gplinux".path;

            address = "10.100.0.2/32";

            peers = {
                servemato = {
                    publicKey = "Cc+IKGfzGNfcS4/InZY89EBtPvXydjs4Ae5/AgBmq0Y=";
                    endpoint = "192.168.0.30:51820";
                    allowedIPs = [ "10.100.0.0/24" ];
                    persistentKeepalive = 25;
                };
            };
        };
    };   
    my.networking.ipv6.method = "auto";

    my.services.ssh.enable = true;

    networking.networkmanager.ensureProfiles.profiles."lan-static" = {
        connection = {
            id = "lan-static";
            type = "ethernet";
            interface-name = "enp6s0";
            autoconnect = true;
        };
        ipv4 = {
            method = "manual";
            addresses = "192.168.0.20/24";
            gateway = "192.168.0.1";
            dns = "10.100.0.1";
        };
    };

    # networking.useHostResolvConf = false;
    networking.nameservers = [ "10.100.0.1" ];

    systemd.services."wireguard-wg-surf".after = [
        "network-online.target"
            "nss-lookup.target"
    ];
    systemd.services."wireguard-wg-surf".wants = [
        "network-online.target"
    ];

    systemd.services."wireguard-wg-surf-peer@".after = [
        "network-online.target"
            "nss-lookup.target"
    ];
    systemd.services."wireguard-wg-surf-peer@".wants = [
        "network-online.target"
    ];


    my.system.binfmt = {
        enable = true;
        emulateAarch64 = true; # to cross compile the raspberry-pi
    };

# Desktop Environment
    my.hardware.nvidia.enable = true;
    my.desktop = {

        enable = true;

        hyprland.enable = true;
        dwm.enable = true;
        river.enable = false;
        plasma.enable = true;

        useDisplayManager = false;
    };

    nix.settings.secret-key-files = [
        "/etc/nix/desktop-cache.key"
    ];

    system.stateVersion = "26.05";
}
