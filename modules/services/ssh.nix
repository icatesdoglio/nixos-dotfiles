{
  lib,
  config,
  ...
}: let
  cfg = config.my.services.ssh;

  wgIp = let
    ips = config.networking.wireguard.interfaces.wg0.ips or [];
  in
    if ips == []
    then null
    else lib.removeSuffix "/24" (builtins.head ips);
in {
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

    services.openssh.listenAddresses = lib.mkIf (cfg.bindToWireguard && wgIp != null) [
      {
        addr = "127.0.0.1";
        port = 22;
      }
      {
        addr = wgIp;
        port = 22;
      }
    ];
    programs.ssh.startAgent = true;

    assertions = [
      {
        assertion = !cfg.bindToWireguard || wgIp != null;
        message = "SSH bindToWireguard requires WireGuard interface wg0 with an IP";
      }
    ];
  };
}
