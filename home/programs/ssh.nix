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

      matchBlocks = {
        "*" = {
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
          addKeysToAgent = "yes";
          serverAliveInterval = 30;
          serverAliveCountMax = 3;
          forwardAgent = false;
        };

        servemato = {
          hostname = "10.100.0.1";
          user = "ian";
          identityFile = "~/.ssh/id_ed25519";
        };

        gp-linux = {
          hostname = "10.100.0.2";
          user = "ian";
          identityFile = "~/.ssh/id_ed25519";
          proxyJump = "servemato";
        };

        mini-mine = {
          hostname = "10.100.0.3";
          user = "ian_cd";
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
