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
        security.sudo.extraConfig = "Defaults timestamp_timeout=60";

        time.timeZone = cfg.timezone;

        nix.settings.experimental-features = [
            "nix-command"
                "flakes"
                "pipe-operators"
        ];
        nix.settings = {
            substituters = [
                "https://cache.nixos.org"
                    "https://nixos-raspberrypi.cachix.org"
            ];
            trusted-public-keys = [
                "desktop-cache:FhWK5ojANXSQA7s6/8bTZNHe59vo87rTCz8oD5aoIo8="
            ];
            extra-trusted-public-keys = [
                "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
            ];
            trusted-users = [ "root" "ian" ];
        };
    };
}
