{ lib, config, ... }:

let
  cfg = config.my.networking.networkmanager;
in
{
  options.my.networking.networkmanager = {
    enable = lib.mkEnableOption "NetworkManager";
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}

