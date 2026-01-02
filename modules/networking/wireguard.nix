{ lib, config, pkgs, ... }:

let
cfg = config.my.networking.wireguard;
in
{
    options.my.networking.wireguard = {
        enable = lib.mkEnableOption "WireGuard (kernel)";

        interfaces = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Kernel WireGuard interface definitions";
        };

        firewallTCPPorts = lib.mkOption {
            type = lib.types.listOf lib.types.port;
            default = [];
        };
    };

    config = lib.mkIf cfg.enable {
        networking.wireguard.enable = true;

        networking.wireguard.useNetworkd = false;

        networking.wireguard.interfaces = cfg.interfaces;

        networking.firewall.interfaces.wg0.allowedTCPPorts =
            cfg.firewallTCPPorts;

        environment.systemPackages = [ pkgs.wireguard-tools ];
    };
}

