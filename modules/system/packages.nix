{ lib, config, pkgs, ... }:

let
    cfg = config.my.system.packages;
in
{
    options.my.system.packages = {
        enable = lib.mkEnableOption "core system packages";

        packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = with pkgs; [
            vim gnupg
            tcpdump
            ];
            description = "System packages expected on all machines";
        };
    };

    config = lib.mkIf cfg.enable {
        environment.systemPackages = cfg.packages;
    };
}
