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
  users.groups.media = {
    gid = 992;
  };

  users.users.qbit = {
    isSystemUser = true;
    uid = 991;
    group = "media";
    home = "/srv/qbit";
    createHome = true;
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

    dnsReservations =
      (lib.mapAttrs' (name: h: lib.nameValuePair "home.${name}.wg" h.wgIP)
        (lib.filterAttrs (_: h: h ? wgIP) hostRegistry))
      // (lib.mapAttrs' (name: h: lib.nameValuePair "home.${name}.lan" h.lanIP)
        (lib.filterAttrs (_: h: h ? lanIP) hostRegistry));

    wildcardDomains = ["servemato.lan"];
  };
  services.caddy = {
    enable = true;

    virtualHosts."seafile.servemato.lan" = {
      extraConfig = ''
        tls internal

        reverse_proxy 127.0.0.1:8082 {
            header_up Host {host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-For {remote}
        }
      '';
    };
  };

  networking.firewall.interfaces.eth0.allowedTCPPorts = [
    22 # SSH
    53 # DNS
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
    8081 # Web UI
    9696 # prowlarr
    9697 # radarr
    9698 # sonarr
    51821 # Torrent port (TCP)
  ];
  networking.firewall.interfaces."ca-van".allowedUDPPorts = [
    51821 # Torrent port (UDP, DHT)
  ];
  networking.firewall.interfaces."ca-van".allowedTCPPorts = [
    51821 # Torrent port (TCP)
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
      address = "10.200.0.2/32";
      privateKeyFile = config.sops.secrets."wg/vps/servemato".path;
      peers = {
        no-snow = {
          publicKey = "eN2zkAgSZJc4/sKnsWvGrFTVbDPUjn858lwSVPn2MGg=";
          allowedIPs = ["10.200.0.1/32"];
          endpoint = "192.210.142.96:51820";
          persistentKeepalive = 25;
        };
      };
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
  systemd.services.wireguard-ca-van.after = [
    "network-online.target"
    "unbound.service"
    "pihole-ftl.service"
  ];
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
    allowedHosts = "10.100.0.1:3000";

    settings = {
      title = "ServeMato";
      theme = "dark";
      color = "slate";
    };

    services = {
      Media = [
        {
          Radarr = {
            href = "http://10.100.0.1:9697";
            description = "Movies";
          };
        }
        {
          Sonarr = {
            href = "http://10.100.0.1:9698";
            description = "TV Shows";
          };
        }
        {
          Prowlarr = {
            href = "http://10.100.0.1:9696";
            description = "Indexers";
          };
        }
        {
          qBittorrent = {
            href = "http://10.100.0.1:8081";
            description = "Downloads";
          };
        }
      ];

      Files = [
        {
          Seafile = {
            href = "https://seafile.servemato.lan";
            description = "File sync and storage";
          };
        }
      ];

      Infrastructure = [
        {
          Pi-hole = {
            href = "http://10.100.0.1:8080";
            description = "DNS";
          };
        }
      ];
    };
  };

  services.qbittorrent = {
    enable = true;
    user = "qbit";
    group = "media";
    profileDir = "/srv/qbit";

    webuiPort = 8081;
    torrentingPort = 51821;

    openFirewall = false; # more restrictive setup

    serverConfig = {
      /*
      download paths
      */
      Downloads.SavePath = "/data/torrents";
      Downloads.TempPath = "/data/torrents/incomplete";
      Downloads.TempPathEnabled = true;

      Preferences.WebUI.Username = "admin";
      Preferences.WebUI.Password_PBKDF2 = "@ByteArray(dtUp2f8XJfCmPuwpvsTtYg==:oueaWDaKo2jY4wREKoAx9mDVGE5nTxVmehZXdYoG/+2zw32CevoVYbA9LYS5dYmsxouiH4mTn9txQJeKwbb99Q==)";
      Preferences."Connection\\Interface" = "ca-van";
      Preferences."Connection\\InterfaceAddress" = "10.14.0.2";

      /*
      security / sanity
      */
      Preferences.WebUI.LocalHostAuth = false;
      Preferences.WebUI.AuthSubnetWhitelistEnabled = false;
      Preferences.WebUI.AuthSubnetWhitelist = "192.168.0.0/24,10.100.0.0/24";

      /*
      optional: don’t expose upnp
      */
      Preferences.Connection.UPnP = false;
      LegalNotice.Accepted = true;
    };
  };

  services.prowlarr = {
    enable = true;
    dataDir = "/srv/prowlarr";

    openFirewall = false;
    settings = {
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

    openFirewall = false;
    settings = {
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
      log.analyticsEnabled = false;
      server.port = 9698;
      update = {
        automatically = false;
        mechanism = "external";
      };
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;

    user = "jellyfin";
    group = "media";
    dataDir = "/srv/jellyfin/data";
    configDir = "/srv/jellyfin/config";
    cacheDir = "/var/cache/jellyfin";
  };

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
          SEAFILE_SERVER_HOSTNAME: seafile.servemato.lan
        depends_on:
          - db
          - memcached
        networks:
          - seafile-net
        restart: unless-stopped

    networks:
      seafile-net:
  '';

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
            echo 'CSRF_TRUSTED_ORIGINS = ["https://seafile.servemato.lan"]' >> "$CONF"
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
    "d /srv 0770 root media -"
    "d /data 0770 root media -"

    "d /srv/media/downloads 0770 qbit media -"

    "d /data/seafile 0770 seafile seafile -"
    "d /data/media 0770 root media -"
    "d /data/syncthing 0770 syncthing syncthing -"

    "d /srv/seafile 0770 seafile seafile -"
    "d /srv/media 0770 root media -"
    "d /srv/syncthing 0770 syncthing syncthing -"

    "d /srv/radarr 0770 radarr media -"
    "d /srv/sonarr 0770 sonarr media -"

    "d /srv/jellyfin 0770 jellyfin media -"
    "d /srv/jellyfin/data 0770 jellyfin media -"
    "d /srv/jellyfin/config 0770 jellyfin media -"
    "d /var/cache/jellyfin 0770 jellyfin media -"
  ];

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
