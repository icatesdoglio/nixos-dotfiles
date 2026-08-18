{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.roles.dns;
in {
  options.my.roles.dns = {
    enable = mkEnableOption "DNS role (Unbound / Cloudflared)";

    useCloudflared = mkOption {
      type = types.bool;
      default = false;
      description = "Use Cloudflared instead of Unbound";
    };

    allowedSubnets = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Subnets allowed to query DNS";
    };
  };

  config =
    mkIf cfg.enable {
    };
}
