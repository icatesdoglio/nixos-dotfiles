{ lib, config, ... }:

let 
    cfg = config.my.system.basics;
in 
{
    options.my.system.basics = {
        enable = lib.mkEnableOption "basic system defaults";

        timezone = lib.mkOption {
            type = lib.types.str;
            default = "America/Los_Angeles";
            description = "System timezone";
        };
    };

    config = lib.mkIf cfg.enable {
        time.timeZone = cfg.timezone;

        nix.settings.experimental-features = [
            "nix-command"
                "flakes"
                "pipe-operators"
        ];
        nix.settings.substituters = [
            "https://cache.nixos.org"
                "https://nixos-raspberrypi.cachix.org"
        ];
    };
}
