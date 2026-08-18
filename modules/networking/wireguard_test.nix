{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.wireguard;
in {
  options.my.wireguard = {
    enable = lib.mkEnableOption "Unified WireGuard module";

    interfaces = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          mode = lib.mkOption {
            type = lib.types.enum ["server" "client" "both"];
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

          mtu = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Optional MTU override for this WireGuard interface";
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

          useWGQuick = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Use wg-quick instead of native WireGuard module.";
          };

          dns = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Optional DNS servers to push in wg-quick mode.";
          };

          nat = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable NAT masquerade on this interface (client full tunnel)";
          };
        };
      }));
      default = {};
      description = "WireGuard interfaces keyed by name (wg0, wg-surf, etc.)";
    };
  };
  config = lib.mkIf cfg.enable (
    let
      # full list of interfaces
      ifaceList = lib.attrValues cfg.interfaces;

      # split wg-quick vs native
      wgQuick = lib.filterAttrs (_: icfg: icfg.useWGQuick) cfg.interfaces;
      wgKernel = lib.filterAttrs (_: icfg: !icfg.useWGQuick) cfg.interfaces;

      # firewall ports
      firewallTCPPorts =
        lib.concatMap (icfg: icfg.firewallTCPPorts) ifaceList;

      firewallUDPPorts = lib.concatMap (
        icfg:
          icfg.firewallUDPPorts
          ++ (
            if icfg.mode != "client" && icfg.listenPort != null
            then [icfg.listenPort]
            else []
          )
      )
      ifaceList;
    in {
      /**
       ****************************
       WireGuard interfaces (native)
      *****************************
      */
      networking.wireguard.interfaces = lib.mapAttrs (
        _name: icfg: let
          base = {
            privateKeyFile = icfg.privateKeyFile;
            peers = lib.mapAttrsToList (_pname: peerCfg: peerCfg) icfg.peers;
          };

          withIp =
            if icfg.address != null
            then base // {ips = [icfg.address];}
            else base;

          withPort =
            if icfg.mode != "client" && icfg.listenPort != null
            then withIp // {listenPort = icfg.listenPort;}
            else withIp;

          withMtu =
            if icfg.mtu != null
            then withPort // {mtu = icfg.mtu;}
            else withPort;
        in
          withMtu
      )
      wgKernel;

      /**
       ****************************
       WireGuard interfaces (wg-quick)
      *****************************
      */
      networking.wg-quick.interfaces = lib.mapAttrs (_name: icfg: {
        # addresses come as list here
        address = lib.mkIf (icfg.address != null) [icfg.address];

        privateKeyFile = icfg.privateKeyFile;

        dns = lib.mkIf (icfg.dns != null) icfg.dns;

        mtu = lib.mkIf (icfg.mtu != null) icfg.mtu;

        peers =
          lib.mapAttrsToList (_pname: peerCfg: {
            publicKey = peerCfg.publicKey;
            allowedIPs = peerCfg.allowedIPs;
            endpoint = peerCfg.endpoint;
            persistentKeepalive =
              lib.mkIf (peerCfg.persistentKeepalive != null)
              peerCfg.persistentKeepalive;
          })
          icfg.peers;

        # NAT (full tunnel client)
        postUp = lib.mkIf icfg.nat ''
          iptables -t nat -A POSTROUTING -o ${icfg.interface} -j MASQUERADE
        '';

        postDown = lib.mkIf icfg.nat ''
          iptables -t nat -D POSTROUTING -o ${icfg.interface} -j MASQUERADE
        '';
      })
      wgQuick;

      /**
       ****************************
       Firewall Aggregation
      *****************************
      */
      networking.firewall.allowedTCPPorts =
        lib.mkAfter firewallTCPPorts;

      networking.firewall.allowedUDPPorts =
        lib.mkAfter firewallUDPPorts;

      /**
       ****************************
       Sanity checks
      *****************************
      */
      assertions =
        lib.mapAttrsToList (name: icfg: {
          assertion = !(icfg.mode != "client" && icfg.address == null);
          message = "WireGuard interface ${name} is in server/both mode but has no address";
        })
        cfg.interfaces;

      /**
       ****************************
       Tools
      *****************************
      */
      environment.systemPackages = [pkgs.wireguard-tools];
    }
  );
}
