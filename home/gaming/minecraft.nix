{ lib, config, pkgs, dotfiles, ... }:

let
cfg = config.my.games.minecraft;
in
{
    options.my.games.minecraft.enable =
        lib.mkEnableOption "Minecraft";

    config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
            prismlauncher
        ];
    };
}

