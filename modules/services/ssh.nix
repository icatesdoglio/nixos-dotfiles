{ lib, config, ... }:

let
  cfg = config.my.services.ssh;

  wgIp =
    let
      ips = config.networking.wireguard.interfaces.wg0.ips or [];
    in
    if ips == [] then null
    else lib.removeSuffix "/24" (builtins.head ips);
in
{
  options.my.services.ssh = {
    enable = lib.mkEnableOption "OpenSSH";

    bindToWireguard = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Bind SSH only to the WireGuard interface";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh.enable = true;

    services.openssh.listenAddresses =
      lib.mkIf (cfg.bindToWireguard && wgIp != null) [
        {
          addr = wgIp;
          port = 22;
        }
      ];

    assertions = [
      {
        assertion =
          !(cfg.bindToWireguard) || wgIp != null;
        message =
          "SSH bindToWireguard requires WireGuard interface wg0 with at least one IP";
      }
    ];
  };
}
