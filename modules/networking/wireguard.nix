{ lib, config, pkgs, ... }:

let
cfg = config.my.wireguard;
in
{
  options.my.wireguard = {
    enable = lib.mkEnableOption "Unified WireGuard module";

    interfaces = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
            options = {
            mode = lib.mkOption {
            type = lib.types.enum [ "server" "client" "both" ];
            default = "client";
            description = ''
            Role of this interface:
            - server: listens + serves peers
            - client: connects outbound
            - both : does both (site-to-site)
            '';
            };

            interface = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Interface name (e.g. wg0, wg-surf)";
            };

            address = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "WireGuard address in CIDR form (e.g. 10.100.0.1/24)";
            };

            listenPort = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
              description = "Port for server/both mode; ignored for pure clients";
            };

            privateKeyFile = lib.mkOption {
              type = lib.types.path;
              description = "PrivateKey file for this host";
            };

            peers = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                  publicKey = lib.mkOption {
                  type = lib.types.str;
                  description = "WireGuard peer public key";
                  };
                  endpoint = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Endpoint (host:port), required for clients";
                  };
                  allowedIPs = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Allowed IP ranges for this peer";
                  default = [];
                  };
                  persistentKeepalive = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "Optional persistent keepalive";
                  };
                  };
              });
              default = {};
              description = ''
                Peer definitions keyed by peer name, e.g.

                peers.seattle.allowedIPs = [ "0.0.0.0/0" ];
              '';
            };
            firewallTCPPorts = lib.mkOption {
              type = lib.types.listOf lib.types.port;
              default = [];
              description = "Extra TCP ports to open on the firewall";
            };

            firewallUDPPorts = lib.mkOption {
              type = lib.types.listOf lib.types.port;
              default = [];
              description = "Extra UDP ports to open on the firewall";
            };
            };
      }));
      default = {};
      description = "WireGuard interfaces keyed by name (wg0, wg-surf, etc.)";
    };
  };

  config = lib.mkIf cfg.enable (
      let
      ifaceList = lib.attrValues cfg.interfaces;

      firewallTCPPorts =
      lib.concatMap (icfg: icfg.firewallTCPPorts) ifaceList;

      firewallUDPPorts =
      lib.concatMap (icfg:
        icfg.firewallUDPPorts
        ++ (if icfg.mode != "client" && icfg.listenPort != null
          then [ icfg.listenPort ]
          else [])
        ) ifaceList;


      in
      {
      /******************************
        WireGuard interfaces
       ******************************/
        networking.wireguard.interfaces =
          lib.mapAttrs (_name: icfg:
              let
              base = {
              privateKeyFile = icfg.privateKeyFile;
              peers = lib.mapAttrsToList (pname: peerCfg:
                  peerCfg // { name = pname; }
                  ) icfg.peers;
              };

              withIp =
              if icfg.address != null then
              base // { ips = [ icfg.address ]; }
              else
              base;

              withPort =
              if icfg.mode != "client" && icfg.listenPort != null then
              withIp // { listenPort = icfg.listenPort; }
              else
              withIp;
              in
                withPort
                ) cfg.interfaces;


              networking.firewall.allowedTCPPorts =
                lib.mkAfter firewallTCPPorts;

              networking.firewall.allowedUDPPorts =
                lib.mkAfter firewallUDPPorts;

              assertions = lib.mapAttrsToList (name: icfg: {
                  assertion = !(icfg.mode != "client" && icfg.address == null);
                  message =
                  "WireGuard interface ${name} is in server/both mode but has no address";
                  }) cfg.interfaces;

              environment.systemPackages = [ pkgs.wireguard-tools ];

      }

  );
}

# vim: ts=2 sts=2 sw=2 et
