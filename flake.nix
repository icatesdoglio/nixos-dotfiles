{
  description = "Ian's NixOS Configuration";

  ##############################################################################
  # Inputs
  ##############################################################################

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Raspberry Pi boot + firmware image builder
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    r423 = {
      url = "github:NixOS/nixpkgs/nixos-23.05";
      flake = false;
    };

    confdev.url = "path:/home/ian/src/confdev";
    suckless.url = "path:/home/ian/src/suckless";
  };

  ##############################################################################
  # Outputs
  ##############################################################################

  outputs = inputs@{
      self, 
    nixpkgs,
    nixos-raspberrypi,
    neovim-nightly-overlay,
    home-manager,
    r423,
    confdev,
    suckless,
    ...
  }:
  let
    overlays = [
      (import neovim-nightly-overlay)
    ];

    dotfiles = self;

  mkSystem = { system, 
      hostPath, 
      enableHM ? false, 
      extraHMArgs ? {},
      extraModules ? []
      }:
      let
      legacy = import r423 {
          system = system;
      };
    in
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs legacy nixpkgs confdev;
        } // extraHMArgs;

        modules = [
              ./users
              ./modules
              ./hosts/${hostPath}
              { nixpkgs.overlays = overlays; }
          ]
          ++extraModules
          ++ (if enableHM then [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ian = {
                imports = [ ./home ./hosts/${hostPath}/home.nix ];
                _module.args = extraHMArgs // { inherit legacy; };
              };
            }
          ] else []);
      };
  in
  {

############################################################################
    # Your systems
    ############################################################################
    nixosConfigurations = {

      ##########################################################################
      # 1. MAIN DESKTOP
      ##########################################################################
      gp-linux = mkSystem {
        system = "x86_64-linux";
        hostPath = "gp-linux";
        enableHM = true;
        extraHMArgs = { confdev = confdev; suckless = suckless; dotfiles = dotfiles; };
      };

      ##########################################################################
      # 2. RASPBERRY PI 5 — using nvmd image builder
      ##########################################################################
    ServeMato = nixos-raspberrypi.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = inputs;

        modules = [
            ({ ... }: {
             imports = with nixos-raspberrypi.nixosModules; [
             raspberry-pi-5.base
             raspberry-pi-5.bluetooth
             ];
             })
            ./users
            ./modules
        ./modules/boot/raspberry-pi.nix
            ./hosts/raspberry-pi/default.nix
        ];
    };
    };
  };
}
