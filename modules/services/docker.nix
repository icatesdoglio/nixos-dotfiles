{ lib, config, ... }:

let
  cfg = config.my.services.docker;
in
{
  options.my.services.docker = {
    enable = lib.mkEnableOption "Docker";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
  };
}

