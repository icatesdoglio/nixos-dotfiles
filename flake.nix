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
        mkSystem = {system, hostPath, extraHMArgs ? {}}:
        let
            pkgs = nixpkgs.legacyPackages.${system};
            legacy = import r423 { inherit system; };
    in nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
            ./hosts/${hostPath}/configuration.nix
            home-manager.nixosModules.home-manager
            {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.users.ian = {
                    imports = [ ./hosts/${hostPath}/home.nix ];
                    _module.args = { inherit legacy;} // extraHMArgs;
                };
            }
        ];
    };
    in 
    
  {
    # -------------------------
    # Desktop host
    # -------------------------
    nixosConfigurations.main-desktop = mkSystem {
      system = "x86_64-linux";
      hostPath = "main-desktop";
      extraHMArgs = { confdev = confdev; };
    };

    # -------------------------
    # Raspberry Pi host (when ready)
    # -------------------------
    # nixosConfigurations.raspberry-pi = mkSystem {
    #   system = "aarch64-linux";
    #   hostPath = "raspberrypi";
    # };
  };
}
