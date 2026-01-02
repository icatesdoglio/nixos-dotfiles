{ lib, config, ... }:

with lib;

let cfg = config.my.networking.static;
in {
  options.my.networking.static = {
    enable = mkEnableOption "static IP";
    interface = mkOption { type = types.str; };
    address = mkOption { type = types.str; };
    gateway = mkOption { type = types.str; };
    nameservers = mkOption { type = types.listOf types.str; };
  };

  config = mkIf cfg.enable {
    networking = {
      useDHCP = false;
      interfaces.${cfg.interface}.ipv4.addresses = [
        { address = cfg.address; prefixLength = 24; }
      ];
      defaultGateway = cfg.gateway;
      nameservers = cfg.nameservers;
    };
  };
}

