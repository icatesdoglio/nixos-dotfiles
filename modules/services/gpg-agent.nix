{ lib, config, pkgs, ... }:

let
  cfg = config.my.services.gpgAgent;
in
{
  options.my.services.gpgAgent = {
    enable = lib.mkEnableOption "GnuPG agent with SSH support";
  };

  config = lib.mkIf cfg.enable {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };
  };
}

