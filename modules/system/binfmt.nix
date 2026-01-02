{ lib, config, ... }:

let
  cfg = config.my.system.binfmt;
in
{
  options.my.system.binfmt = {
    enable = lib.mkEnableOption "binfmt emulation support";

    emulateAarch64 = lib.mkEnableOption "aarch64 emulation (for Raspberry Pi builds)";
  };

  config = lib.mkIf cfg.enable {

    systemd.services.systemd-binfmt.enable = true;

    boot.binfmt.emulatedSystems =
      lib.mkIf cfg.emulateAarch64 [ "aarch64-linux" ];

    nix.settings = lib.mkIf cfg.emulateAarch64 {
      extra-platforms = [ "aarch64-linux" ];

      substituters = [
        "https://cache.nixos.org"
        "https://nixos-raspberrypi.cachix.org"
      ];

      trusted-public-keys = [
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      ];
    };

    assertions = [
      {
        assertion = !cfg.emulateAarch64 || cfg.enable;
        message = "emulateAarch64 requires binfmt support to be enabled";
      }
    ];
  };
}

