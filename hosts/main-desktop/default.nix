{ ... }:

{

    imports = [
        ./hardware-configuration.nix
    ];

    networking.hostName = "gp-linux";

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

    my.services.ssh = {
        enable = true;
        bindToWireguard = true;
    };

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


    my.boot.systemd = {
        enable = true;
        emulateAarch64 = true; # To build the Raspberry Pi
    };

    # Desktop Environment
    my.desktop.audio.enable = true;
    my.desktop.fonts.enable = true;
    my.hardware.nvidia.enable = true;
    my.desktop.hyprland.enable = true;

    nix.settings.secret-key-files = [
        "/etc/nix/desktop-cache.key"
    ];

    system.stateVersion = "26.05";
}
