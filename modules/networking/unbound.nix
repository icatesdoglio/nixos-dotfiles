{ lib, config, ... }:
let 
    cfg = config.my.networking.unbound;
in
{
  options.my.networking.unbound = {
    enable = lib.mkEnableOption "Unbound recursive DNS Resolver";
  };

  config = lib.mkIf cfg.enable {
    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "127.0.0.1" "10.100.0.1" ];
          access-control = [
              "127.0.0.1/32 allow"
                  "10.100.0.0/24 allow"
          ];
          port = 5335;
          do-ip4 = "yes";
          do-ip6 = "no";
          do-tcp = "yes";

          harden-referral-path = "yes";
          hide-identity = "yes";
          hide-version = "yes";

          auto-trust-anchor-file = "/var/lib/unbound/root.key";

          prefetch = "yes";
          prefetch-key = "yes";
          msg-cache-size = "50m";
          rrset-cache-size = "100m";

          forward-zone = [];
        };
      };
    };
  };
}

