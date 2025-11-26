{
    description = "Ian's NixOS Configuration";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-unstable";
        neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        r423 = {
            url = "github:NixOS/nixpkgs/nixos-23.05";
            flake = false;
        };
    confdev.url = "path:/home/ian/confdev";
    };

    outputs = { self, nixpkgs, neovim-nightly-overlay, home-manager, r423, confdev, ... }:
        let
        system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    legacy = import r423 { inherit system; };
    in {

        nixosConfigurations.main = nixpkgs.lib.nixosSystem {
            system = system;
            modules = [
                ./configuration.nix
            ];
        };
        homeConfigurations.main = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;

            modules = [
            { nixpkgs.overlays = [ (import neovim-nightly-overlay) ]; }
            {
                home.username = "ian";
                home.homeDirectory = "/home/ian";

                _module.args = {
                    inherit legacy confdev;
                };
            }

            ./home.nix
            ];
        };
    };
}
