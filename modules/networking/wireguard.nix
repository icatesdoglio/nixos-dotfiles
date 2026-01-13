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
            type = lib.types.listOf lib.types.attrs;
            default = [];
            description = "Peer definitions (server OR client)";
          };

          dns = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Override DNS servers when this interface is up";
          };

          nat.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable NAT masquerading out via externalInterface";
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

          externalInterface = lib.mkOption {
            type = lib.types.str;
            default = "eth0";
            description = "Outbound interface for NAT";
          };
        };
      }));
      default = {};
      description = "WireGuard interfaces keyed by name (wg0, wg-surf, etc.)";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge (
      lib.mapAttrsToList (_name: icfg: {
        # Core WireGuard interface
        networking.wireguard.interfaces.${icfg.interface} = {
          ips = lib.mkIf (icfg.address != null) [ icfg.address ];
          privateKeyFile = icfg.privateKeyFile;
          listenPort = lib.mkIf (icfg.mode != "client" && icfg.listenPort != null) icfg.listenPort;
          peers = icfg.peers;
        };

        # NAT
        networking.nat = lib.mkIf icfg.nat.enable {
          enable = true;
          internalInterfaces = [ icfg.interface ];
          externalInterface = icfg.externalInterface;
        };

        # DNS override
        networking.nameservers =
          lib.mkIf (icfg.dns != []) icfg.dns;

        networking.useHostResolvConf =
          lib.mkIf (icfg.dns != []) false;

        # Firewall
        networking.firewall.allowedTCPPorts =
          lib.mkAfter icfg.firewallTCPPorts;

        networking.firewall.allowedUDPPorts =
          lib.mkAfter (
            icfg.firewallUDPPorts
            ++ (if icfg.mode != "client" && icfg.listenPort != null
                then [ icfg.listenPort ]
                else [])
          );
      }) cfg.interfaces
    ) // {
      assertions = lib.mapAttrsToList (name: icfg: {
        assertion = !(icfg.mode != "client" && icfg.address == null);
        message = "WireGuard interface ${name} is in server/both mode but has no address";
      }) cfg.interfaces;

      environment.systemPackages = [ pkgs.wireguard-tools ];
    }
  );
}

