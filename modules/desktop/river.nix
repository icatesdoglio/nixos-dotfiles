{ lib, config, pkgs, ... }:

let 
    cfg = config.my.desktop.river; 
in
{
    options.my.desktop.river = {
        enable = lib.mkEnableOption "Enable River (Wayland Compositor)";
    };

    config = lib.mkIf cfg.enable {

        programs.river-classic = {
            enable = true;
            xwayland.enable = true;
        };

        services.seatd.enable = false;

        xdg.portal = {
            enable = true;
            wlr.enable = true;
        };

        environment.systemPackages = with pkgs; [
            swaybg
            mako
            swaylock
            lswt
        ];
    };
}
