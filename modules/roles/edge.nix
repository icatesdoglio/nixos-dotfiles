{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.roles.edge;
in {
  options.my.roles.edge = {
    enable = mkEnableOption "Edge server role (VPN + DNS)";

    vpnSubnet = mkOption {
      type = types.str;
      default = "10.100.0.0/24";
      description = "Subnet served by WireGuard";
    };

    listenPort = mkOption {
      type = types.port;
      default = 51820;
      description = "WireGuard port";
    };

    interface = mkOption {
      type = types.str;
      default = "wg0";
    };

    externalInterface = mkOption {
      type = types.str;
      default = "eth0";
      description = "Outbound interface for NAT";
    };

    useCloudflaredDNS = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # DNS is bundled, but user can override role settings
    my.roles.dns = {
      enable = true;
      useCloudflared = cfg.useCloudflaredDNS;
      allowedSubnets = [cfg.vpnSubnet "127.0.0.0/8"];
    };

    my.wireguard.enable = true;

    my.wireguard.interfaces.${cfg.interface} = {
      mode = "server";
      interface = cfg.interface;
      listenPort = cfg.listenPort;

      firewallUDPPorts = [cfg.listenPort];
    };

    assertions = [
      {
        assertion = config.my.wireguard.enable;
        message = "Edge implies WireGuard enabled";
      }
      {
        assertion = config.my.roles.dns.enable;
        message = "Edge implies DNS enabled";
      }
    ];
  };
}
