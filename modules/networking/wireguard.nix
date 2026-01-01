{ pkgs, lib, config, ... }:

let
  cfg = config.my.networking.wireguard;
in
{
  options.my.networking.wireguard = {
    enable = lib.mkEnableOption "WireGuard";

    interfaces = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "WireGuard interface definitions";
    };

    firewallTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [];
      description = "Allowed TCP ports on WireGuard interfaces";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wireguard.interfaces = cfg.interfaces;

    networking.firewall.interfaces.wg0.allowedTCPPorts =
      cfg.firewallTCPPorts;

    environment.systemPackages = with pkgs; [
        wireguard-tools
    ];
  };
}

