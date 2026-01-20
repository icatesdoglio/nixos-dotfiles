{ pkgs, lib, config, ... }:

{
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

    /******
      SOPS
     *****/
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
    };

    environment.systemPackages = with pkgs; [ age sops ssh-to-age iproute2 nftables ];

    users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
    ];

    /**********************************
      Edge Roll: VPN start & CloudFlare
     **********************************/
    my.roles.edge = {
        enable = true;
        vpnSubnet = "10.100.0.0/24";
        listenPort = 51820;         
        useCloudflaredDNS = false;  
        interface = "wg0";          
    };

    /* Static Networking Setup */

    my.networking.static = {
        enable = true;
        interface = "eth0";
        address = "192.168.0.30";
        gateway = "192.168.0.1";
        nameservers = [ "127.0.0.1" ];
    };
    my.networking.ipv6.method = "ignore";

    /**************
      service users 
     **************/
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

    users.users.media = {
        isSystemUser = true;
        uid = 992;
        group = "media";
        home = "/srv/media";
        createHome = true;
    };


    /**********************************
      Pi-Hole and DNS resolution
     ***********************************/
    networking.nat = {
        enable = true;
        externalInterface = "eth0";
        internalInterfaces = [ "wg0" ];
    };
    networking.firewall.checkReversePath = "loose";


    my.networking.unbound.enable = true;
    my.networking.pihole = {
        enable = true;
        hostIP = "10.100.0.1";

        dnsReservations = {
            "pihole.servemato.lan" = "10.100.0.1";
            "home.servemato.lan" = "10.100.0.1";
        };

        wildcardDomains = [ "servemato.lan" ];

    };
    networking.firewall.interfaces.eth0.allowedUDPPorts = [ 
        51820 # Wireguard
    ];
    networking.firewall.interfaces.wg0.allowedUDPPorts = [ 
        53      # DNS
        51820   # Wireguard
        51821   # Torrent port (UDP, DHT)
        51822   # Wireguard -- VPS
    ];
    networking.firewall.interfaces.wg0.allowedTCPPorts = [ 
        22      # SSH
        53      # DNS
        3000    # Home Page
        8081    # Web UI
        9696    # Prowlarr UI
        51821   # Torrent port (TCP)
    ];
    networking.firewall.interfaces."ca-van".allowedUDPPorts = [ 
        51821   # Torrent port (UDP, DHT)
    ];
    networking.firewall.interfaces."ca-van".allowedTCPPorts = [ 
        51821   # Torrent port (TCP)
    ];

    /*************
      VPN Settings
     *************/

    my.wireguard = {
        enable = true;

        interfaces.wg0 = {
            mode = "server";
            listenPort = 51820;
            privateKeyFile = config.sops.secrets."wg/lan/servemato".path;
            address = "10.100.0.1/24";

          peers = {
              desktop = {
                  publicKey = "E3J+BJ2f+6VyLY8JB7ypzSOXdQsB66T/nr7mdcP4yxc=";
                  allowedIPs = [ "10.100.0.2/32" ];
              };

              macmini = {
                  publicKey = "GXxa4bsYmIeLdvnznaNiX8kzOwfjoRCJTMG3uUrFCXk=";
                  allowedIPs = [ "10.100.0.3/32" ];
              };

              iphone = {
                  publicKey = "hlZRXkdEdoHLpigkr3cP23X2qu89tf1Lj3hUbeMtGAw=";
                  allowedIPs = [ "10.100.0.4/32" ];
              };

              archlaptop = {
                  publicKey = "mx/c3oFZwTQ824bA4kXPyr+CU0qVLO28imgENyEZgUU=";
                  allowedIPs = [ "10.100.0.5/32" ];
              };
              framework = {
                  publicKey = "8A7L4okGuJSPtHIHxVNcTT18iGKr50Ipz18G9LAQKgE=";
                  allowedIPs = [ "10.100.0.6/32" ];
              };
          };
          postSetup = ''
              ${pkgs.iproute2}/bin/ip rule add \
              iif wg0 \
              lookup main \
              priority 900 \
              2>/dev/null || true
              '';

          postShutdown = ''
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
                    allowedIPs = [ "10.200.0.1/32" ];
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

    /* EXTRA CUSTOM routing for ca-van to make the service work */
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
    /* Tighten ca-van against spoofing */ 
    /*
    networking.firewall.extraRules = ''
        iifname "wg0" ip saddr != 10.100.0.0/24 drop 

        iifname "ca-van" ip saddr 10.0.0.0/8 drop
        iifname "ca-van" ip saddr 172.16.0.0/12 drop
        iifname "ca-van" ip saddr 192.168.0.0/16 drop
        '';
        */

    /* TODO:
       the this wireguard setup requires DNS 
       So must wait for unbound
       there's almost certainly a cleaner solution
     */
    systemd.services.wireguard-ca-van.after = [
        "network-online.target"
            "unbound.service"
            "pihole-ftl.service"
    ];


    /*** ensure domain in cloudflare has correct configuration" ***/
    services.cloudflare-dyndns = {
        enable = true;
        apiTokenFile = config.sops.secrets."cloudflare/api_key".path;
        domains = [ "home.iancd.net" ];
        ipv4 = true;
        ipv6 = false;
        proxied = false;
    };

    /*********************
     *** server config ***
     *********************/

    /* landing page */
    services.homepage-dashboard = {
        enable = true;

        listenPort = 3000;

        allowedHosts = "10.100.0.1:3000";

        settings = {
            title = "servemato";
            theme = "dark";
            color = "slate";
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
                /* download paths */
                Downloads.SavePath = "/data/torrents";
                Downloads.TempPath = "/data/torrents/incomplete";
                Downloads.TempPathEnabled = true;

                Preferences.WebUI.Username = "admin"; 
                Preferences.WebUI.Password_PBKDF2 = 
                    "@ByteArray(dtUp2f8XJfCmPuwpvsTtYg==:oueaWDaKo2jY4wREKoAx9mDVGE5nTxVmehZXdYoG/+2zw32CevoVYbA9LYS5dYmsxouiH4mTn9txQJeKwbb99Q==)";
                Preferences."Connection\\Interface" = "ca-van";
                Preferences."Connection\\InterfaceAddress"= "10.14.0.2";

                /* security / sanity */
                Preferences.WebUI.LocalHostAuth = false;
                Preferences.WebUI.AuthSubnetWhitelistEnabled = true;
                Preferences.WebUI.AuthSubnetWhitelist = "192.168.0.0/24,10.100.0.0/24";

                /* optional: don’t expose upnp */
                Preferences.Connection.UPnP = false;
                LegalNotice.Accepted = true;
            };
    };

    services.prowlarr = {
        enable = true;
        openFirewall = false;
        settings.server.port = 9696;
    };

    zramSwap.enable = true;


    /***********
      substituters 
     ************/
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
        listenAddresses = [
        { addr = "10.100.0.1"; port = 22; }
        { addr = "192.168.0.30"; port = 22; }
        ];
    };

    system.stateVersion = "26.05";
}

