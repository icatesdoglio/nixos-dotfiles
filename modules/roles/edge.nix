{ lib, config, ... }:

with lib;

let
  cfg = config.my.roles.edge;
in
{
  options.my.roles.edge = {
    enable = mkEnableOption "Edge server role (VPN + DNS)";

    vpnSubnet = mkOption {
      type = types.str;
      default = "10.100.0.0/24";
      description = "WireGuard subnet served by this edge node";
    };

    useCloudflaredDNS = mkOption {
      type = types.bool;
      default = true;
      description = "Route DNS traffic through Cloudflared";
    };
  };

  config = mkIf cfg.enable {

    #### Enable composed roles
    my.roles.dns = {
      enable = true;
      useCloudflared = cfg.useCloudflaredDNS;
      allowedSubnets = [
        cfg.vpnSubnet
        "127.0.0.0/8"
      ];
    };

    my.wireguard.server = {
      enable = true;
      subnet = cfg.vpnSubnet;
    };

    #### Cross-role safety guarantees
    assertions = [
      {
        assertion = config.my.roles.dns.enable;
        message = "Edge role requires DNS role to be enabled";
      }
      {
        assertion = config.my.wireguard.server.enable;
        message = "Edge role requires WireGuard server role to be enabled";
      }
    ];
  };
}

