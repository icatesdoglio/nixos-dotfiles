{
  lib,
  pkgs,
  config,
  hostRegistry,
  ...
}: let
  qbitCommon = {
    savePath = "/data/torrents/complete";
    tempPath = "/data/torrents/incomplete";
    username = "admin";
    password = "@ByteArray(dtUp2f8XJfCmPuwpvsTtYg==:oueaWDaKo2jY4wREKoAx9mDVGE5nTxVmehZXdYoG/+2zw32CevoVYbA9LYS5dYmsxouiH4mTn9txQJeKwbb99Q==)";
    authSubnet = "192.168.0.0/24,10.100.0.0/24";
  };

  mkQbitConfig = {
    interface,
    interfaceAddress,
    torrentingPort,
    extraPrefs ? "",
  }:
    pkgs.writeText "qBittorrent.conf" ''
      [BitTorrent]
      Session\Port=${toString torrentingPort}

      [LegalNotice]
      Accepted=true

      [Preferences]
      Connection\Interface=${interface}
      Connection\InterfaceAddress=${interfaceAddress}
      Connection\PortRangeMin=${toString torrentingPort}
      Connection\UPnP=false
      Downloads\SavePath=${qbitCommon.savePath}
      Downloads\TempPath=${qbitCommon.tempPath}
      Downloads\TempPathEnabled=true
      WebUI\AuthSubnetWhitelist=${qbitCommon.authSubnet}
      WebUI\AuthSubnetWhitelistEnabled=false
      WebUI\LocalHostAuth=false
      WebUI\Password_PBKDF2="${qbitCommon.password}"
      WebUI\Username=${qbitCommon.username}
      ${extraPrefs}
    '';

  mkQbitService = {
    user,
    profileDir,
    configFile,
    webuiPort,
    torrentingPort,
    vpnService ? null,
  }: let
    vpnDeps = lib.optional (vpnService != null) vpnService;
  in {
    wants = ["network-online.target"] ++ vpnDeps;
    after = ["local-fs.target" "network-online.target" "nss-lookup.target"] ++ vpnDeps;
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "media";
      UMask = "0002";
      ExecStartPre = ''
        ${pkgs.coreutils}/bin/install -Dm600 ${configFile} ${profileDir}/qBittorrent/config/qBittorrent.conf
      '';
      ExecStart = ''
        ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --profile=${profileDir} --webui-port=${toString webuiPort} --torrenting-port=${toString torrentingPort}
      '';
      TimeoutStopSec = 1800;
      PrivateTmp = false;
      PrivateNetwork = false;
      RemoveIPC = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProtectHome = "yes";
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectSystem = "full";
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK"];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      CapabilityBoundingSet = "";
      SystemCallFilter = ["@system-service"];
    };
  };
in {
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

  /**
   ****
   SOPS
  ****
  */
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
    "wg/vps/servemato" = {
      sopsFile = ../../secrets/wireguard.yaml;
      format = "yaml";
      path = "/etc/wireguard/wg-vps.key";
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
    "seafile-admin-password" = {
      sopsFile = ../../secrets/seafile.yaml;
      format = "yaml";
      path = "/run/secrets/seafile-admin-password";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "mariadb-root-password" = {
      sopsFile = ../../secrets/seafile.yaml;
      format = "yaml";
      path = "/run/secrets/mariadb-root-password";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "seafile-db-password" = {
      sopsFile = ../../secrets/seafile.yaml;
      format = "yaml";
      path = "/run/secrets/seafile-db-password";
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  environment.systemPackages = with pkgs; [age sops ssh-to-age iproute2 nftables podman-compose];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
  ];

  /**
   ********************************
   Edge Roll: VPN start & CloudFlare
  *********************************
  */
  my.roles.edge = {
    enable = true;
    vpnSubnet = "10.100.0.0/24";
    listenPort = 51820;
    useCloudflaredDNS = false;
    interface = "wg0";
  };

  /*
  Static Networking Setup
  */

  my.networking.static = {
    enable = true;
    interface = "eth0";
    address = "192.168.0.30";
    gateway = "192.168.0.1";
    nameservers = ["127.0.0.1"];
  };
  my.networking.ipv6.method = "ignore";

  /**
   ************
   service users
  *************
  */
  users.groups.media = {gid = 985;};

  users.users.qbit = {
    isSystemUser = true;
    uid = 991;
    group = "media";
    home = "/srv/qbit";
    createHome = true;
  };

  users.users."qbit-private" = {
    isSystemUser = true;
    uid = 990;
    group = "media";
    home = "/srv/qbit-private";
    createHome = true;
  };

  users.users.jellyfin = {
    isSystemUser = true;
    uid = 992;
    group = "media";
  };


  users.users.seafile = {
    isSystemUser = true;
    uid = 994;
    group = "seafile";
    home = "/srv/seafile";
    createHome = true;
  };

  users.groups.seafile = {
    gid = 995;
  };

  /**
   ********************************
   Pi-Hole and DNS resolution
  **********************************
  */
  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = ["wg0"];
  };
  networking.firewall.checkReversePath = "loose";

  my.networking.unbound.enable = true;
  my.networking.pihole = {
    enable = true;
    hostIP = "10.100.0.1";
    wildcardDomains = ["servemato.iancd.net"];
    # Explicit bind prevents dnsmasq from grabbing 0.0.0.0:53, which
    # conflicts with podman aardvark-dns on container bridge IPs.
    listenAddresses = ["127.0.0.1" "192.168.0.30" "10.100.0.1"];
  };

  # Host records derived from registry — dnsmasq reads /etc/hosts natively,
  # giving both A and PTR records. Names with dots are served as-is (no expand-hosts).
  networking.hosts =
    (lib.mapAttrs' (name: h: lib.nameValuePair h.wgIP ["${name}.wg"])
      (lib.filterAttrs (_: h: h ? wgIP) hostRegistry))
    // (lib.mapAttrs' (name: h: lib.nameValuePair h.lanIP ["${name}.lan"])
      (lib.filterAttrs (_: h: h ? lanIP) hostRegistry));
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
      # Run `nixos-rebuild build` with this placeholder — the error will print
      # the correct hash; paste it here and rebuild again.
      hash = "sha256-+nSmZNTdPv7d/T7qijkggyAf77RP17M6j4Cez/oha8Q=";
    };

    globalConfig = ''
      email iancatesdoglio@gmail.com
    '';

    extraConfig = ''
      *.servemato.iancd.net {
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }

        @seafile  host seafile.servemato.iancd.net
        @jellyfin host jellyfin.servemato.iancd.net
        @radarr   host radarr.servemato.iancd.net
        @sonarr   host sonarr.servemato.iancd.net
        @prowlarr host prowlarr.servemato.iancd.net
        @qbit     host qbit.servemato.iancd.net
        @bazarr   host bazarr.servemato.iancd.net
        @readarr  host readarr.servemato.iancd.net
        @abs      host abs.servemato.iancd.net
        @home     host home.servemato.iancd.net
        @pihole   host pihole.servemato.iancd.net
        @tdarr    host tdarr.servemato.iancd.net

        handle @seafile {
          reverse_proxy 127.0.0.1:8082 {
            header_up Host {host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-For {remote}
          }
        }
        handle @jellyfin {
          reverse_proxy 127.0.0.1:8096 {
            header_up Host {host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-For {remote}
          }
        }
        handle @radarr   { reverse_proxy 127.0.0.1:9697 }
        handle @sonarr   { reverse_proxy 127.0.0.1:9698 }
        handle @prowlarr { reverse_proxy 127.0.0.1:9696 }
        handle @qbit     { reverse_proxy 127.0.0.1:8081 }
        handle @bazarr   { reverse_proxy 127.0.0.1:6767 }
        handle @readarr  { reverse_proxy 127.0.0.1:8787 }
        handle @abs      { reverse_proxy 127.0.0.1:13378 }
        handle @home     { reverse_proxy 127.0.0.1:3000 }
        handle @pihole   { reverse_proxy 127.0.0.1:8080 }
        handle @tdarr    { reverse_proxy 127.0.0.1:8265 }

        handle { respond 404 }
      }
    '';
  };

  # Write the Cloudflare API token into an env file readable by the caddy user
  # before caddy starts. EnvironmentFiles is cleaner than embedding secrets in
  # the Caddyfile or in systemd Environment= (which shows up in `systemctl show`).
  systemd.services.caddy-env = {
    description = "Prepare Caddy Cloudflare token";
    requiredBy = ["caddy.service"];
    before = ["caddy.service"];
    after = ["sops-nix.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "caddy-env-setup" ''
        install -m 640 /dev/null /run/caddy-cf.env
        chown root:caddy /run/caddy-cf.env
        printf 'CLOUDFLARE_API_TOKEN=%s\n' \
          "$(cat ${config.sops.secrets."cloudflare/api_key".path})" \
          > /run/caddy-cf.env
      '';
    };
  };
  systemd.services.caddy.serviceConfig.EnvironmentFile = ["/run/caddy-cf.env"];

  networking.firewall.interfaces.eth0.allowedTCPPorts = [
    22 # SSH
    53 # DNS
    2049 # NFS
    8096 # jellyfin
    8266 # tdarr server (node connections from gp-linux)
  ];
  networking.firewall.interfaces.eth0.allowedUDPPorts = [
    51820 # Wireguard
  ];
  networking.firewall.interfaces.wg0.allowedUDPPorts = [
    53 # DNS
    51820 # Wireguard
    51821 # Torrent port (UDP, DHT)
    51822 # Wireguard -- VPS
  ];
  networking.firewall.interfaces.wg0.allowedTCPPorts = [
    22 # SSH
    53 # DNS
    80 # HTTP (Caddy)
    443 # HTTPS (Caddy)
    3000 # Home Page
    6767 # bazarr
    8081 # qBittorrent Web UI
    8083 # qBittorrent MAM Web UI
    8096 # jellyfin
    8787 # readarr
    13378 # audiobookshelf
    9696 # prowlarr
    9697 # radarr
    9698 # sonarr
    8191 # flaresolverr
    51821 # Torrent port (TCP)
  ];
  networking.firewall.interfaces."ca-van".allowedUDPPorts = [
    51821 # Torrent port (UDP, DHT)
  ];
  networking.firewall.interfaces."ca-van".allowedTCPPorts = [
    51821 # Torrent port (TCP)
  ];
  networking.firewall.interfaces."wg-vps".allowedUDPPorts = [
    51823 # MAM torrent port (UDP, DHT)
  ];
  networking.firewall.interfaces."wg-vps".allowedTCPPorts = [
    51823 # MAM torrent port (TCP)
  ];

  /**
   ***********
   VPN Settings
  ************
  */

  my.wireguard = {
    enable = true;

    interfaces.wg0 = {
      mode = "server";
      listenPort = 51820;
      privateKeyFile = config.sops.secrets."wg/lan/servemato".path;
      address = "10.100.0.1/24";

      peers = lib.mapAttrs (_: h: {
        publicKey = h.wgPublicKey;
        allowedIPs = ["${h.wgIP}/32"];
      }) (lib.filterAttrs (name: _: name != "servemato") hostRegistry);
      postSetup = ''
        ${pkgs.iproute2}/bin/ip rule add \
        to 10.100.0.0/24 \
        lookup main \
        priority 840 \
        2>/dev/null || true

        ${pkgs.iproute2}/bin/ip rule add \
        iif wg0 \
        lookup main \
        priority 900 \
        2>/dev/null || true
      '';

      postShutdown = ''
        ${pkgs.iproute2}/bin/ip rule del \
        to 10.100.0.0/24 \
        lookup main \
        priority 840 \
        2>/dev/null || true

        ${pkgs.iproute2}/bin/ip rule del \
        iif wg0 \
        lookup main \
        priority 900 \
        2>/dev/null || true
      '';
    };
    interfaces.wg-vps = {
      mode = "client";
      table = "off";
      allowedIPsAsRoutes = false;
      address = "10.200.0.2/32";
      privateKeyFile = config.sops.secrets."wg/vps/servemato".path;
      peers = {
        no-snow = {
          publicKey = "eN2zkAgSZJc4/sKnsWvGrFTVbDPUjn858lwSVPn2MGg=";
          allowedIPs = ["0.0.0.0/0"];
          endpoint = "192.210.142.96:51820";
          persistentKeepalive = 25;
        };
      };

      postSetup = let
        uid = toString config.users.users."qbit-private".uid;
      in ''
        ${pkgs.iproute2}/bin/ip rule del \
        uidrange ${uid}-${uid} \
        lookup 210 priority 1100 2>/dev/null || true

        ${pkgs.iproute2}/bin/ip rule del \
        uidrange ${uid}-${uid} \
        blackhole priority 1101 2>/dev/null || true

        ${pkgs.iproute2}/bin/ip route replace 10.200.0.1 dev wg-vps
        ${pkgs.iproute2}/bin/ip route replace default dev wg-vps table 210

        ${pkgs.iproute2}/bin/ip rule add \
        uidrange ${uid}-${uid} \
        lookup 210 priority 1100

        ${pkgs.iproute2}/bin/ip rule add \
        uidrange ${uid}-${uid} \
        blackhole priority 1101
      '';

      postShutdown = let
        uid = toString config.users.users."qbit-private".uid;
      in ''
        ${pkgs.iproute2}/bin/ip rule del \
        uidrange ${uid}-${uid} \
        lookup 210 priority 1100 || true

        ${pkgs.iproute2}/bin/ip rule del \
        uidrange ${uid}-${uid} \
        blackhole priority 1101 || true

        ${pkgs.iproute2}/bin/ip route del default dev wg-vps table 210 || true
        ${pkgs.iproute2}/bin/ip route del 10.200.0.1 dev wg-vps || true
      '';
    };
    interfaces.ca-van = {
      mode = "client";
      table = "off";
      allowedIPsAsRoutes = false;
      privateKeyFile = config.sops.secrets."wg/surfshark/servemato".path;
      address = "10.14.0.2/16";
      peers = {
        VAN = {
          publicKey = "o4HezxSsbNqJFJZj+VBw/QXFLpfNo7PZu8xe7H2hTw0=";
          allowedIPs = ["0.0.0.0/0"];
          endpoint = "ca-van.prod.surfshark.com:51820";
          persistentKeepalive = 25;
        };
      };

      postSetup = let
        uid = toString config.users.users.qbit.uid;
      in ''
        ${pkgs.iproute2}/bin/ip route add default dev ca-van table 200

        ${pkgs.iproute2}/bin/ip rule add \
        uidrange ${uid}-${uid} \
        lookup 200 priority 1000

        ${pkgs.iproute2}/bin/ip rule add \
        uidrange ${uid}-${uid} \
        blackhole priority 1001
      '';

      postShutdown = let
        uid = toString config.users.users.qbit.uid;
      in ''
        ${pkgs.iproute2}/bin/ip rule del \
        uidrange ${uid}-${uid} \
        lookup 200 priority 1000 || true

        ${pkgs.iproute2}/bin/ip rule del \
        uidrange ${uid}-${uid} \
        blackhole priority 1001 || true

        ${pkgs.iproute2}/bin/ip route del default dev ca-van table 200 || true
      '';
    };
  };

  /*
  EXTRA CUSTOM routing for ca-van to make the service work
  */
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.conf.ca-van.rp_filter" = 0;
    "net.ipv4.conf.wg0.rp_filter" = 0;
    "net.ipv4.conf.eth0.rp_filter" = 0;
  };

  networking.firewall.extraCommands = ''
    iptables -t nat -A POSTROUTING -o ca-van -j MASQUERADE
  '';

  networking.firewall.extraStopCommands = ''
    iptables -t nat -D POSTROUTING -o ca-van -j MASQUERADE || true
  '';

  /*
  TODO:
  the this wireguard setup requires DNS
  So must wait for unbound
  there's almost certainly a cleaner solution
  */
  systemd.services.wireguard-ca-van = {
    after = [
      "network-online.target"
      "unbound.service"
      "pihole-ftl.service"
    ];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
  };
  systemd.services.unbound = {
    after = ["network.target"];
    wants = ["network.target"];
    wantedBy = ["multi-user.target"];
  };

  /**
  * ensure domain in cloudflare has correct configuration" **
  */
  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets."cloudflare/api_key".path;
    domains = ["home.iancd.net"];
    ipv4 = true;
    ipv6 = false;
    proxied = false;
  };

  /**
   *******************
  *** server config ***
  ********************
  */

  /*
  landing page
  */
  services.homepage-dashboard = {
    enable = true;
    listenPort = 3000;
    allowedHosts = "home.servemato.iancd.net";

    settings = {
      title = "ServeMato";
      theme = "dark";
      color = "slate";
    };

    services = [
      {
        Media = [
          {Jellyfin = {href = "https://jellyfin.servemato.iancd.net"; description = "Media server";};}
          {Radarr = {href = "https://radarr.servemato.iancd.net"; description = "Movies";};}
          {Sonarr = {href = "https://sonarr.servemato.iancd.net"; description = "TV Shows";};}
          {Readarr = {href = "https://readarr.servemato.iancd.net"; description = "Audiobooks & Books";};}
          {Audiobookshelf = {href = "https://abs.servemato.iancd.net"; description = "Audiobook & ebook library";};}
          {Bazarr = {href = "https://bazarr.servemato.iancd.net"; description = "Subtitles";};}
          {Prowlarr = {href = "https://prowlarr.servemato.iancd.net"; description = "Indexers";};}
          {qBittorrent = {href = "https://qbit.servemato.iancd.net"; description = "Downloads";};}
          {Tdarr = {href = "https://tdarr.servemato.iancd.net"; description = "Transcoding";};}
        ];
      }
      {
        Files = [
          {Seafile = {href = "https://seafile.servemato.iancd.net"; description = "File sync and storage";};}
        ];
      }
      {
        Infrastructure = [
          {"Pi-hole" = {href = "https://pihole.servemato.iancd.net"; description = "DNS";};}
        ];
      }
    ];
  };

  systemd.services.qbittorrent-public = mkQbitService {
    user = "qbit";
    profileDir = "/srv/qbit";
    webuiPort = 8081;
    torrentingPort = 51821;
    configFile = mkQbitConfig {
      interface = "ca-van";
      interfaceAddress = "10.14.0.2";
      torrentingPort = 51821;
      extraPrefs = ''
        Bittorrent\MaxRatio=2.0
        Bittorrent\MaxRatioAction=0
        BitTorrent\Session\MaxActiveUploads=50
      '';
    };
  };

  systemd.services.qbittorrent-private = mkQbitService {
    user = "qbit-private";
    profileDir = "/srv/qbit-private";
    webuiPort = 8083;
    torrentingPort = 51823;
    vpnService = "wireguard-wg-vps.service";
    configFile = mkQbitConfig {
      interface = "wg-vps";
      interfaceAddress = "10.200.0.2";
      torrentingPort = 51823;
      extraPrefs = ''
        BitTorrent\Session\MaxActiveUploads=50
      '';
    };
  };

  services.prowlarr = {
    enable = true;
    dataDir = "/srv/prowlarr";

    openFirewall = false;
    settings = {
      auth.method = "Forms";
      auth.required = "DisabledForLocalAddresses";
      log.analyticsEnabled = false;
      server.port = 9696;
      update = {
        automatically = false;
        mechanism = "external";
      };
    };
  };
  services.radarr = {
    enable = true;
    dataDir = "/srv/radarr";
    group = "media";

    openFirewall = false;
    settings = {
      auth.method = "Forms";
      auth.required = "DisabledForLocalAddresses";
      log.analyticsEnabled = false;
      server.port = 9697;
      update = {
        automatically = false;
        mechanism = "external";
      };
    };
  };
  services.sonarr = {
    enable = true;
    dataDir = "/srv/sonarr";
    user = "sonarr";
    group = "media";

    openFirewall = false;
    settings = {
      auth.method = "Forms";
      auth.required = "DisabledForLocalAddresses";
      log.analyticsEnabled = false;
      server.port = 9698;
      update = {
        automatically = false;
        mechanism = "external";
      };
    };
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /data/media 192.168.0.20(rw,sync,no_subtree_check,no_root_squash)
    '';
  };


  services.jellyfin = {
    enable = true;
    openFirewall = false;

    user = "jellyfin";
    group = "media";
    dataDir = "/srv/jellyfin/data";
    configDir = "/srv/jellyfin/config";
    cacheDir = "/var/cache/jellyfin";
  };

  services.bazarr = {
    enable = true;
    openFirewall = false;
  };

  services.readarr = {
    enable = true;
    dataDir = "/srv/readarr";
    group = "media";
    openFirewall = false;
    settings = {
      auth.method = "Forms";
      auth.required = "DisabledForLocalAddresses";
      log.analyticsEnabled = false;
      server.port = 8787;
      update = {
        automatically = false;
        mechanism = "external";
      };
    };
  };

  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 13378;
    group = "media";
    openFirewall = false;
  };

  systemd.services.prowlarr.serviceConfig = {
    SupplementaryGroups = ["media"];
    ExecStartPre = "+" + toString (pkgs.writeShellScript "prowlarr-preseed" ''
      if [ ! -f /var/lib/prowlarr/config.xml ]; then
        cat > /var/lib/prowlarr/config.xml <<'XML'
<Config>
  <AuthenticationMethod>Forms</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Port>9696</Port>
  <LogLevel>info</LogLevel>
  <Branch>main</Branch>
</Config>
XML
      fi
    '');
  };

  systemd.services.radarr.serviceConfig.ExecStartPre = "+" + toString (pkgs.writeShellScript "radarr-preseed" ''
    if [ ! -f ${config.services.radarr.dataDir}/config.xml ]; then
      cat > ${config.services.radarr.dataDir}/config.xml <<'XML'
<Config>
  <AuthenticationMethod>Forms</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Port>9697</Port>
  <LogLevel>info</LogLevel>
  <Branch>main</Branch>
</Config>
XML
      chown radarr:media ${config.services.radarr.dataDir}/config.xml
      chmod 0660 ${config.services.radarr.dataDir}/config.xml
    fi
  '');

  systemd.services.readarr.environment.READARR__METADATASOURCE = "https://api.bookinfo.pro";

  systemd.services.readarr.serviceConfig.ExecStartPre = "+" + toString (pkgs.writeShellScript "readarr-preseed" ''
    if [ ! -f /srv/readarr/config.xml ]; then
      cat > /srv/readarr/config.xml <<'XML'
<Config>
  <AuthenticationMethod>Forms</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Port>8787</Port>
  <LogLevel>info</LogLevel>
  <Branch>develop</Branch>
</Config>
XML
      chown readarr:media /srv/readarr/config.xml
      chmod 0660 /srv/readarr/config.xml
    fi
  '');

  systemd.services.sonarr.serviceConfig.ExecStartPre = "+" + toString (pkgs.writeShellScript "sonarr-preseed" ''
    if [ ! -f ${config.services.sonarr.dataDir}/config.xml ]; then
      cat > ${config.services.sonarr.dataDir}/config.xml <<'XML'
<Config>
  <AuthenticationMethod>Forms</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Port>9698</Port>
  <LogLevel>info</LogLevel>
  <Branch>main</Branch>
</Config>
XML
      chown sonarr:media ${config.services.sonarr.dataDir}/config.xml
      chmod 0660 ${config.services.sonarr.dataDir}/config.xml
    fi
  '');

  systemd.services.bazarr.serviceConfig.SupplementaryGroups = ["media"];

  environment.etc."flaresolverr/docker-compose.yml".text = ''
    services:
      flaresolverr:
        image: ghcr.io/flaresolverr/flaresolverr:latest
        ports:
          - "127.0.0.1:8191:8191"
        environment:
          LOG_LEVEL: info
        restart: unless-stopped
  '';

  systemd.services.flaresolverr = {
    description = "FlareSolverr Proxy";
    after = ["podman.socket" "network-online.target"];
    requires = ["podman.socket"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f /etc/flaresolverr/docker-compose.yml up -d";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f /etc/flaresolverr/docker-compose.yml down";
    };
  };

  environment.etc."tdarr/docker-compose.yml".text = ''
    services:
      tdarr:
        image: ghcr.io/haveagitgat/tdarr:2.74.01
        ports:
          - "127.0.0.1:8265:8265"
          - "8266:8266"
        volumes:
          - /srv/tdarr:/app/server
          - /data/media:/data/media
        environment:
          PUID: "1000"
          PGID: "985"
          serverPort: "8266"
          webUIPort: "8265"
          rootDataPath: /app/server
          openBrowser: "false"
        restart: unless-stopped
  '';

  environment.etc."seafile/docker-compose.yml".text = ''
    services:
      db:
        image: mariadb:10.11
        environment:
          MYSQL_ROOT_PASSWORD: ''${MYSQL_ROOT_PASSWORD}
          MYSQL_LOG_CONSOLE: "true"
          MARIADB_AUTO_UPGRADE: "1"
        volumes:
          - /srv/seafile/db:/var/lib/mysql
        networks:
          - seafile-net
        restart: unless-stopped

      memcached:
        image: memcached:1.6.29
        entrypoint: memcached -m 256
        networks:
          - seafile-net
        restart: unless-stopped

      seafile:
        image: seafileltd/seafile-mc:11.0-latest
        ports:
          - "127.0.0.1:8082:80"
        volumes:
          - /srv/seafile/data:/shared
        environment:
          DB_HOST: db
          DB_ROOT_PASSWD: ''${MYSQL_ROOT_PASSWORD}
          DB_PASSWORD: ''${SEAFILE_DB_PASSWORD}
          SEAFILE_ADMIN_EMAIL: iancatesdoglio@gmail.com
          SEAFILE_ADMIN_PASSWORD: ''${SEAFILE_ADMIN_PASSWORD}
          SEAFILE_SERVER_LETSENCRYPT: "false"
          SEAFILE_SERVER_HOSTNAME: seafile.servemato.iancd.net
        depends_on:
          - db
          - memcached
        networks:
          - seafile-net
        restart: unless-stopped

    networks:
      seafile-net:
  '';

  systemd.services.tdarr = {
    description = "Tdarr Transcoding Server";
    after = ["podman.socket" "network-online.target"];
    requires = ["podman.socket"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f /etc/tdarr/docker-compose.yml up -d";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f /etc/tdarr/docker-compose.yml down";
    };
  };

  systemd.services.seafile = {
    description = "Seafile Compose Stack";
    after = ["podman.socket" "network-online.target"];
    requires = ["podman.socket"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = pkgs.writeShellScript "seafile-setup-env" ''
        install -m 0600 /dev/null /run/seafile.env
        printf 'MYSQL_ROOT_PASSWORD=%s\n' "$(sed 's/\$/\$\$/g' ${config.sops.secrets."mariadb-root-password".path})" >> /run/seafile.env
        printf 'SEAFILE_DB_PASSWORD=%s\n'  "$(sed 's/\$/\$\$/g' ${config.sops.secrets."seafile-db-password".path})"  >> /run/seafile.env
        printf 'SEAFILE_ADMIN_PASSWORD=%s\n' "$(sed 's/\$/\$\$/g' ${config.sops.secrets."seafile-admin-password".path})" >> /run/seafile.env

        CONF=/srv/seafile/data/seafile/conf/seahub_settings.py
        if [ -f "$CONF" ] && ! grep -q 'CSRF_TRUSTED_ORIGINS' "$CONF"; then
            echo 'CSRF_TRUSTED_ORIGINS = ["https://seafile.servemato.iancd.net"]' >> "$CONF"
        fi
      '';
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f /etc/seafile/docker-compose.yml --env-file /run/seafile.env up -d";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f /etc/seafile/docker-compose.yml down";
      ExecReload = "${pkgs.docker-compose}/bin/docker-compose -f /etc/seafile/docker-compose.yml pull";
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # provides `docker` CLI
    dockerSocket.enable = true;
  };

  systemd.tmpfiles.rules = [
    "z /srv 0770 root media -"
    "z /data 0770 root media -"

    "d /data/torrents 0770 root media -"
    "d /data/torrents/complete 0770 root media -"
    "d /data/torrents/incomplete 0770 root media -"
    "d /srv/qbit 0755 qbit media -"
    "d /srv/qbit/qBittorrent 0755 qbit media -"
    "d /srv/qbit/qBittorrent/config 0755 qbit media -"
    "d /srv/qbit-private 0755 qbit-private media -"
    "d /srv/qbit-private/qBittorrent 0755 qbit-private media -"
    "d /srv/qbit-private/qBittorrent/config 0755 qbit-private media -"
    "d /data/media/movies 0770 root media -"
    "d /data/media/tv 0770 root media -"

    "d /data/seafile 0770 seafile seafile -"
    "d /data/media 0770 root media -"
    "d /data/syncthing 0770 syncthing syncthing -"

    "d /srv/seafile 0770 seafile seafile -"
    "d /srv/media 0770 root media -"
    "d /srv/syncthing 0770 syncthing syncthing -"

    "d /srv/prowlarr 0770 root media -"
    "d /srv/readarr 0770 readarr media -"
    "d /data/media/audiobooks 0770 root media -"
    "d /data/media/books 0770 root media -"
    "d /srv/radarr 0770 radarr media -"
    "d /srv/sonarr 0770 sonarr media -"
    "d /srv/bazarr 0770 root media -"

    "d /srv/tdarr 0770 root media -"
    "d /srv/jellyfin 0770 jellyfin media -"
    "d /srv/jellyfin/data 0770 jellyfin media -"
    "d /srv/jellyfin/config 0770 jellyfin media -"
    "d /var/cache/jellyfin 0770 jellyfin media -"
  ];

  system.activationScripts.arrStateOwnership.text = ''
    mkdir -p /srv/radarr /srv/sonarr /srv/readarr
    chown -R radarr:media /srv/radarr
    chown -R sonarr:media /srv/sonarr
    chown -R readarr:media /srv/readarr
    chmod -R u+rwX,g+rwX,o-rwx /srv/radarr /srv/sonarr /srv/readarr
  '';

  fileSystems."/srv/seafile" = {
    device = "/data/seafile";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/srv/media" = {
    device = "/data/media";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/srv/syncthing" = {
    device = "/data/syncthing";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/var/cache/jellyfin" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["size=4G" "mode=0770"];
  };

  zramSwap.enable = true;

  /**
   *********
   substituters
  ***********
  */
  nix.settings = {
    substituters = [
      "ssh-ng://ian@10.100.0.2"
      "ssh-ng://ian@gp-linux"
      "ssh-ng://ian@10.100.0.6"
      "ssh-ng://ian@framework"
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "desktop-cache:fhwk5ojanxsqa7s6/8btznhe59vo87rtcz8od5aoio8="
    ];
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  /*
  external drive
  */
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/3a2dd4a8-d3b8-4a1d-8636-fdf0907ec2ce";
    fsType = "ext4";
    options = ["noatime"];
  };

  system.stateVersion = "26.05";
}
