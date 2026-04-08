{
  lib,
  config,
  ...
}: let
  cfg = config.my.desktop.audio;
in {
  options.my.desktop.audio = {
    enable = lib.mkEnableOption "PipeWire audio stack";
  };

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    users.users.ian.extraGroups =
      lib.mkAfter ["audio"];
  };
}
