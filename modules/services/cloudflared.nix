{
  lib,
  config,
  ...
}: let
  cfg = config.my.services.cloudflared;
in {
  options.my.services.cloudflared = {
    enable = lib.mkEnableOption "Cloudflared tunnel";

    tunnelId = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflared tunnel UUID";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "Tunnel credentials JSON file";
    };

    ingress = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Ingress rules for the tunnel";
    };
  };

  config = lib.mkIf cfg.enable {
    services.cloudflared = {
      enable = true;

      tunnels."${cfg.tunnelId}" = {
        inherit (cfg) credentialsFile ingress;
      };
    };
  };
}
