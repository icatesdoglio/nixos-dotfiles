{ ... }:

{

    imports = [
        ./hardware-configuration.nix
    ];

    my.host = {
        name = "gp-linux";
        role = "desktop";
        platform = "x86_64";
    };

    my.networking.wireguard = {
        enable = true;

        interfaces.wg0 = {
            ips = [ "10.100.0.2/24" ];
            privateKeyFile = "/etc/wireguard/desktop.key";

            peers = [
            {
                publicKey = "Cc+IKGfzGNfcS4/InZY89EBtPvXydjs4Ae5/AgBmq0Y=";
                endpoint = "192.168.0.30:51820";
                allowedIPs = [ "10.100.0.0/24" ];
                persistentKeepalive = 25;
            }
            ];
        };

        firewallTCPPorts = [ 22 ];
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
            dns = "192.168.0.1;1.1.1.1";
        };
    };


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
        river.enable = true;

        useDisplayManager = false;
    };

    nix.settings.secret-key-files = [
        "/etc/nix/desktop-cache.key"
    ];

    system.stateVersion = "26.05";
}
