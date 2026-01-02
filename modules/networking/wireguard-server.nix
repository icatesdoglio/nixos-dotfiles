{ lib, config, ... }:

let
  cfg = config.my.wireguard.server;
in
{
  options.my.wireguard.server = {
    enable = lib.mkEnableOption "WireGuard server";

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
    };

    subnet = lib.mkOption {
      type = lib.types.str;
      default = "10.100.0.0/24";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "10.100.0.1/24";
    };

    peers = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "WireGuard peer definitions";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ cfg.listenPort ];

    networking.wireguard.interfaces.wg0 = {
      ips = [ cfg.address ];
      listenPort = cfg.listenPort;
      privateKeyFile = "/etc/wireguard/server.key";
      peers = cfg.peers;
    };
  };
}

