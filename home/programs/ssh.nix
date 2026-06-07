{
  lib,
  config,
  ...
}: let
  cfg = config.my.hm.programs.ssh;
in {
  options.my.hm.programs.ssh.enable =
    lib.mkEnableOption "SSH configuration";

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        "*" = {
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
          AddKeysToAgent = "yes";
          ServerAliveInterval = 30;
          ServerAliveCountMax = 3;
          ForwardAgent = false;
        };

        servemato = {
          Hostname = "10.100.0.1";
          User = "ian";
          IdentityFile = "~/.ssh/id_ed25519";
        };

        racknerd = {
          Hostname = "192.210.142.96";
          User = "ian";
          IdentityFile = "~/.ssh/id_ed25519";
        };

        mam-relay = {
          Hostname = "192.210.142.96";
          User = "ian";
          IdentityFile = "~/.ssh/id_ed25519";
        };

        gp-linux = {
          Hostname = "10.100.0.2";
          User = "ian";
          IdentityFile = "~/.ssh/id_ed25519";
          ProxyJump = "servemato";
        };

        mini-mine = {
          Hostname = "10.100.0.3";
          User = "ian_cd";
          IdentityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
