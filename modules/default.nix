{ ... }:

{
    imports = [
        ./bootstrap.nix
        ./boot
        ./system
        ./services
        ./networking
        ./hardware
        ./desktop
    ];
}

