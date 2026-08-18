{
  lib,
  config,
  ...
}: {
  config = lib.mkMerge [
    #### Global defaults (safe everywhere)
    {
      my.system = {
        basics.enable = lib.mkDefault true;
        packages.enable = lib.mkDefault true;
      };

      my.services.ssh.enable = lib.mkDefault true;
    }

    #### Desktop-only defaults
    (lib.mkIf (config.my.host.role == "desktop") {
      my.networking.networkmanager.enable = lib.mkDefault true;

      my.services.gpgAgent.enable = lib.mkDefault true;

      my.desktop = {
        audio.enable = lib.mkDefault true;
        fonts.enable = lib.mkDefault true;
      };
    })

    #### Server / Pi defaults
    (lib.mkIf (config.my.host.role == "server") {
      my.networking.networkmanager.enable = lib.mkDefault false;
    })

    #### Cross-cutting policy: Docker → docker group
    (lib.mkIf config.my.services.docker.enable {
      users.users.ian.extraGroups =
        lib.mkAfter ["docker"];
    })
  ];
}
