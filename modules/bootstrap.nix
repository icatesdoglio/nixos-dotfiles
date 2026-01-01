{ lib, config, ... }:

{
  config = lib.mkMerge [
    # Default policy for all hosts
    {
      my = {
        networking = {
          networkmanager.enable = lib.mkDefault true;
        };

        system = {
          basics.enable = lib.mkDefault true;
          packages.enable = lib.mkDefault true;
        };

        services = {
          ssh.enable = lib.mkDefault true;
          gpgAgent.enable = lib.mkDefault true;
        };
        desktop = {
            audio.enable = lib.mkDefault true;
            fonts.enable = lib.mkDefault true;
        };
      };
    }

    # Cross-cutting policy: Docker → docker group
    (lib.mkIf config.my.services.docker.enable {
      users.users.ian.extraGroups =
        lib.mkAfter [ "docker" ];
    })
  ];
}

