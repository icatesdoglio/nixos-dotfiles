{ lib, config, ... }:

let
  cfg = config.my.networking.ipv6;
in
{
  options.my.networking.ipv6 = {
    method = lib.mkOption {
      type = lib.types.enum [ "ignore" "auto" "dhcp" ];
      default = "auto";
      description = ''
        IPv6 configuration method:
        - "ignore": disable IPv6
        - "auto": SLAAC / router advertisements
        - "dhcp": DHCPv6
      '';
    };
  };

  config = lib.mkMerge [
    # Fully disable IPv6
    (lib.mkIf (cfg.method == "ignore") {
      networking.enableIPv6 = false;
    })

    # Explicitly enable IPv6 (default on NixOS, but this is declarative)
    (lib.mkIf (cfg.method != "ignore") {
      networking.enableIPv6 = true;
    })
  ];
}

