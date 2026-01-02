{ lib, config, ... }:

with lib;

let
  cfg = config.my.services.unbound;
in
{
  options.my.services.unbound = {
    enable = mkEnableOption "Unbound DNS resolver";

    listenAddresses = mkOption {
      type = types.listOf types.str;
      default = [ "127.0.0.1" ];
    };

    accessControl = mkOption {
      type = types.listOf types.str;
      default = [ "127.0.0.0/8 allow" ];
    };

    forwarders = mkOption {
      type = types.listOf types.str;
      default = [ "1.1.1.1" "8.8.8.8" ];
      description = "Upstream DNS servers";
    };
  };

  config = mkIf cfg.enable {
    services.unbound = {
      enable = true;

      settings = {
        server = {
          interface = cfg.listenAddresses;
          access-control = cfg.accessControl;

          do-ip6 = false;
          hide-identity = true;
          hide-version = true;

          prefetch = true;
          cache-min-ttl = 60;
          cache-max-ttl = 86400;
        };

        forward-zone = [{
          name = ".";
          forward-addr = cfg.forwarders;
        }];
      };
    };
  };
}

