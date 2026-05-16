{
  lib,
  pkgs,
  config,
  hostRegistry,
  ...
}: {
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

  /**
   ******
   SOPS
  *******
  */
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

      mtu = 1280;
      address = "10.100.0.6/32";

      peers = {
        servemato = {
          # Servemato LAN hub
          publicKey = "Cc+IKGfzGNfcS4/InZY89EBtPvXydjs4Ae5/AgBmq0Y=";
          endpoint = "home.iancd.net:51820";
          allowedIPs = ["10.100.0.0/24"];
          persistentKeepalive = 25;
        };
        # gp-linux = {
        #   # Servemato LAN hub
        #   publicKey = "E3J+BJ2f+6VyLY8JB7ypzSOXdQsB66T/nr7mdcP4yxc=";
        #   allowedIPs = ["10.100.0.2/32"];
        #   persistentKeepalive = 25;
        # };
      };
    };
  };

  networking.wg-quick.interfaces.ca-van = {
    address = ["10.14.0.2/16"];
    autostart = false;

    privateKeyFile = config.sops.secrets."wg/surfshark/framework".path;

    table = "51820";

    dns = ["162.252.172.57" "149.154.159.92"];

    extraOptions = {
      fwmark = 51820;
    };

    peers = [
      {
        publicKey = "o4HezxSsbNqJFJZj+VBw/QXFLpfNo7PZu8xe7H2hTw0=";
        allowedIPs = ["0.0.0.0/0"];
        endpoint = "ca-van.prod.surfshark.com:51820";
        persistentKeepalive = 25;
      }
    ];
    postUp = ''
      ip rule add not fwmark 51820 lookup 51820
      ip rule add lookup main suppress_prefixlength 0
    '';

    postDown = ''
      ip rule del not fwmark 51820 lookup 51820 || true
      ip rule del lookup main suppress_prefixlength 0 || true
    '';
  };

  my.networking.ipv6.method = "ignore";
  networking.nat.enable = true;
  networking.nat.externalInterface = "wlan0";

  # MT7925 (WiFi 7): disable ASPM to prevent PCIe power-state freeze,
  # disable CLC to suppress 6 GHz regulatory failures that cause roaming loop
  boot.extraModprobeConfig = ''
    options mt7925e disable_aspm=1
    options mt7925_common disable_clc=1
  '';

  my.services.ssh.enable = true;

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.firewall.checkReversePath = "loose";
  networking.networkmanager.ensureProfiles.profiles."home-static" = {
    connection = {
      id = "home-static";
      type = "wifi";
      interface-name = "wlan0";
      autoconnect = true;
      autoconnect-priority = 50;
    };

    wifi = {
      ssid = "Tomato Info";
      mode = "infrastructure";
    };

    ipv4 = {
      method = "manual";
      addresses = "192.168.0.60/24";
      gateway = "192.168.0.1";
      dns = "10.100.0.1";
      # ignore-auto-dns = true;
    };
    ipv6.method = "ignore";
  };

  # When on home WiFi, connect directly to ServeMato's LAN IP to avoid hairpin NAT.
  # On all other networks, use the public hostname.
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "wg0-endpoint-switch" ''
        IFACE="$1"
        ACTION="$2"

        [ "$IFACE" = "wlan0" ] || exit 0

        SERVEMATO_KEY="${hostRegistry.servemato.wgPublicKey}"

        case "$ACTION" in
          up)
            SSID=$(${pkgs.networkmanager}/bin/nmcli -g 802-11-wireless.ssid \
              connection show "$CONNECTION_UUID" 2>/dev/null)
            if [ "$SSID" = "Tomato Info" ]; then
              ${pkgs.wireguard-tools}/bin/wg set wg0 peer "$SERVEMATO_KEY" \
                endpoint "${hostRegistry.servemato.lanIP}:51820"
            else
              ${pkgs.wireguard-tools}/bin/wg set wg0 peer "$SERVEMATO_KEY" \
                endpoint "home.iancd.net:51820"
            fi
            ;;
          down)
            ${pkgs.wireguard-tools}/bin/wg set wg0 peer "$SERVEMATO_KEY" \
              endpoint "home.iancd.net:51820"
            ;;
        esac
      '';
    }
  ];

  services.resolved.enable = false;

  /**
   ************
   Laptop Config
  *************
  */
  nixpkgs.config.allowUnfree = true;
  /*
  Audio
  */
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  hardware.bluetooth = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    alsa-utils
    pulseaudio
    pavucontrol
    spotify
    dig
    jellyfin-desktop
    mpv
    wineWow64Packages.stable
    seafile-client
  ];
  hardware.enableAllFirmware = true;
  hardware.firmware = [pkgs.sof-firmware];

  /*
  TODO: Bug in nvidia code somewhere gets auto enabled
  */
  services.xserver.videoDrivers = ["amdgpu"];

  /*
  Desktop configurations
  */
  my.desktop = {
    enable = true;

    hyprland.enable = true;
    dwm.enable = true;
    river.enable = true;
    plasma.enable = false;

    useDisplayManager = false;
  };

  users.groups.games = {
    gid = 993;
  };
  users.users.ian.extraGroups = lib.mkAfter ["games"];

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  services.flatpak.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

    xdg.portal.config.common.default = "hyprland";

  # services.caddy.enable = true;

  system.stateVersion = "26.05";
}
