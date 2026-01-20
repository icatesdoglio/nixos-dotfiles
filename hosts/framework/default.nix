{ lib, pkgs, config, sops-nix, ... }:

{

	imports = [
		./hardware-configuration.nix
	];


	my.host = {
		name = "framework";
		role = "laptop";
		platform = "x86_64";
	};

    my.system.binfmt = {
        enable = true;
        emulateAarch64 = true; # to cross compile the raspberry-pi
    };

    /********
      SOPS
     ********/
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";

    sops.secrets = {
        "wg/surfshark/framework" = {
            sopsFile = ../../secrets/wireguard.yaml;
            format = "yaml";
            path = "/etc/wireguard/wg-surf.key";
            owner = "root";
            group = "root";
            mode = "0400";
        };
        "wg/lan/framework" = {
            sopsFile = ../../secrets/wireguard.yaml;
            format = "yaml";
            path = "/etc/wireguard/wg0.key";
            owner = "root";
            group = "root";
            mode = "0400";
        };
    };


	my.wireguard = {
        enable = true;

        interfaces.wg0 = {
            mode = "client";

            privateKeyFile = config.sops.secrets."wg/lan/framework".path;

            address = "10.100.0.6/32";

            peers = {
                servemato = {  # Servemato LAN hub
                    publicKey = "Cc+IKGfzGNfcS4/InZY89EBtPvXydjs4Ae5/AgBmq0Y=";
                    endpoint = "home.iancd.net:51820";
                    allowedIPs = [ "10.100.0.0/24" ];
                    persistentKeepalive = 25;
                };
            };
        };
    };
 

    networking.firewall.package = pkgs.iptables;

    my.networking.ipv6.method = "ignore";
    networking.nat.enable = true;
    networking.nat.externalInterface = "wlp191s0";



	my.services.ssh.enable = true;

    networking.networkmanager.enable = true;
    networking.firewall.checkReversePath = "loose";
    networking.networkmanager.ensureProfiles.profiles."home-static" = {
        connection = {
            id = "home-static";
            type = "wifi";
                interface-name = "wlp191s0";
                autoconnect = false;
        };

        wifi = {
            ssid = "Tomato Info";
                mode = "infrastructure";
        };

        ipv4 = {
            method = "manual";
            addresses = "192.168.0.60/24";
            gateway = null;
            dns = "10.100.0.1,162.252.172.57,149.154.159.92";
        };
    };

    networking.networkmanager.ensureProfiles.profiles."wifi-auto" = {
        connection = {
            id = "wifi-auto";
            type = "wifi";
            interface-name = "wlp191s0";
            autoconnect = true;
        };
        ipv4.method = "auto";
    };
    networking.nameservers = [ "192.168.0.30" "162.252.172.57" "149.154.159.92" "1.1.1.1" ];


    /**************
      Laptop Config
     **************/
    nixpkgs.config.allowUnfree = true;
    /* Audio */
    services.pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
    };
    hardware.bluetooth.enable = true;
    environment.systemPackages = with pkgs; [
        alsa-utils      
            pulseaudio  
            pavucontrol 
    ];
    hardware.enableAllFirmware = true;
    hardware.firmware = [ pkgs.sof-firmware ];



    /* TODO: Bug in nvidia code somewhere gets auto enabled */
	services.xserver.videoDrivers = lib.mkForce [ "amdgpu" ];

    /* Desktop configurations */
	my.desktop = {

		enable = true;

		hyprland.enable = true;
		dwm.enable = true;
		river.enable = false;
		plasma.enable = false;

		useDisplayManager = false;
	};

    programs.steam = {
        enable = true;
        extraCompatPackages = with pkgs; [
            proton-ge-bin
        ];
    };

    system.stateVersion = "26.05";
}
