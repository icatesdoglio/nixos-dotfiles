{ lib, pkgs, ... }:

{

	imports = [
		./hardware-configuration.nix
	];


	my.host = {
		name = "framework";
		role = "laptop";
		platform = "x86_64";
	};

	my.wireguard = {
		enable = true;
		interfaces.wg0 = {
			mode = "client";
			interface = "wg0";
			privateKeyFile = "/etc/wireguard/wg0.key";

			address = "10.100.0.6/32";

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

    networking.networkmanager.enable = true;
	networking.networkmanager.ensureProfiles.profiles."lan-static" = {
		connection = {
			id = "lan-static";
			type = "ethernet";
			interface-name = "enp6s0";
			autoconnect = true;
		};
		ipv4 = {
			method = "manual";
			addresses = "192.168.0.60/24";
			gateway = "192.168.0.1";
			dns = "10.100.0.1";
		};
	};

    nixpkgs.config.allowUnfree = true;

    services.pulseaudio.enable = false;
    hardware.bluetooth.enable = true;

    services.pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
    };

    hardware.enableAllFirmware = true;
    hardware.firmware = [ pkgs.sof-firmware ];

    environment.systemPackages = with pkgs; [
        alsa-utils      
            pulseaudio  
            pavucontrol 
    ];



	services.xserver.videoDrivers = lib.mkForce [ "amdgpu" ];
	my.desktop = {

		enable = true;

		hyprland.enable = true;
		dwm.enable = true;
		river.enable = false;
		plasma.enable = false;

		useDisplayManager = false;
	};

	system.stateVersion = "26.05";
}
