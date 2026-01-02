{ ... }:

{
    imports = [
        ./bootstrap.nix
        ./hostname.nix
        ./boot
        ./system
        ./services
        ./networking
        ./hardware
        ./desktop
        ./roles
    ];
}

