{
  config,
  pkgs,
  hostRegistry,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  my.host = {
    name = "gp-linux";
    role = "desktop";
    platform = "x86_64";
  };

  /**
   ****
   SOPS
  ****
  */
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

  /**
   ***********
   VPN Settings
  ************
  */
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
          allowedIPs = ["10.100.0.0/24"];
          persistentKeepalive = 25;
        };
        framework = {
          publicKey = hostRegistry.framework.wgPublicKey;
          allowedIPs = ["${hostRegistry.framework.wgIP}/32"];
        };
      };
    };
  };
  my.networking.ipv6.method = "ignore";

  my.services.ssh.enable = true;

  users.groups.media = {gid = 985;};

  users.users.tdarr = {
    isSystemUser = true;
    uid = 988;
    group = "tdarr";
    extraGroups = ["media"];
  };

  users.groups.tdarr = {};

  fileSystems."/data/media" = {
    device = "192.168.0.30:/data/media";
    fsType = "nfs";
    options = ["nfsvers=4.1" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600"];
  };

  systemd.services.tdarr-server = {
    description = "Tdarr Media Transcoding Server";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    environment = {
      serverPort = "8266";
      webUIPort = "8265";
      rootDataPath = "/var/lib/tdarr/server";
      ffmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
      ffprobePath = "${pkgs.ffmpeg}/bin/ffprobe";
      handbrakePath = "${pkgs.handbrake}/bin/HandBrakeCLI";
      openBrowser = "false";
    };
    serviceConfig = {
      Type = "simple";
      User = "tdarr";
      Group = "tdarr";
      ExecStart = "${pkgs.tdarr-server}/bin/tdarr-server";
      Restart = "on-failure";
      RestartSec = "5s";
      StateDirectory = "tdarr/server";
      WorkingDirectory = "/var/lib/tdarr/server";
    };
  };

  systemd.services.tdarr-node = {
    description = "Tdarr Media Transcoding Node";
    after = ["network-online.target" "data-media.mount"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    environment = {
      serverURL = "http://192.168.0.30:8266";
      nodeName = "gp-linux";
      transcodegpuWorkers = "1";
      transcodecpuWorkers = "2";
      healthcheckcpuWorkers = "1";
      rootDataPath = "/var/lib/tdarr/nodes/gp-linux";
      ffmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
      ffprobePath = "${pkgs.ffmpeg}/bin/ffprobe";
    };
    serviceConfig = {
      Type = "simple";
      User = "tdarr";
      Group = "media";
      ExecStart = "${pkgs.tdarr-node}/bin/tdarr-node";
      Restart = "on-failure";
      RestartSec = "5s";
      StateDirectory = "tdarr/nodes/gp-linux";
      WorkingDirectory = "/var/lib/tdarr/nodes/gp-linux";
    };
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
      dns = "10.100.0.1";
    };
  };

  # networking.useHostResolvConf = false;
  # networking.nameservers = [ "10.100.0.1" ];

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

  /**
  Desktop Environment *
  */
  my.hardware.nvidia.enable = true;
  my.desktop = {
    enable = true;

    hyprland.enable = true;
    dwm.enable = true;
    river.enable = true;
    plasma.enable = true;

    useDisplayManager = false;
  };

  nix.settings.secret-key-files = [
    "/etc/nix/desktop-cache.key"
  ];

  environment.systemPackages = with pkgs; [
    seafile-client
    seafile-shared
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

    programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
            gtk2
                glib
                libX11
                libXext
                libXrender
                libXtst
                libXrandr
                libXcursor
                libXinerama
                pango
                cairo
                gdk-pixbuf
        ];
    };
    system.stateVersion = "26.05";
}
