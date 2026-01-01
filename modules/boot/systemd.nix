{ lib, config, ... }:

let
  cfg = config.my.boot.systemd;
in
{
  options.my.boot.systemd = {
    enable = lib.mkEnableOption "systemd-boot bootloader";

    emulateAarch64 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable aarch64 emulation and Raspberry Pi build support";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # ─────────────────────────────────────────────
    # Bootloader
    # ─────────────────────────────────────────────
    {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    }

    # ─────────────────────────────────────────────
    # AArch64 / Raspberry Pi support
    # ─────────────────────────────────────────────
    (lib.mkIf cfg.emulateAarch64 {
      systemd.services.systemd-binfmt.enable = true;

      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      nix.settings = {
        extra-platforms = [ "aarch64-linux" ];

        substituters = [
          "https://cache.nixos.org"
          "https://nixos-raspberrypi.cachix.org"
        ];

        trusted-public-keys = [
          "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
      };
    })

    # ─────────────────────────────────────────────
    # Safety
    # ─────────────────────────────────────────────
    {
      assertions = [
        {
          assertion =
            !cfg.emulateAarch64 || config.systemd.services.systemd-binfmt.enable;
          message =
            "emulateAarch64 requires systemd-binfmt to be enabled";
        }
      ];
    }
  ]);
}

