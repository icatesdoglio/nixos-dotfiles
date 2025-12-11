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

    confdev.url = "path:/home/ian/confdev";
  };

  ##############################################################################
  # Cache for nvmd prebuilt Pi images
  ##############################################################################

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
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
    ...
  }:
  let
    overlays = [
      (import neovim-nightly-overlay)
    ];

    # Your mkSystem for desktop + HM integration
    mkSystem = { system, hostPath, enableHM ? false, extraHMArgs ? {} }:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        legacy = import r423 { inherit system; };
      in
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs legacy nixpkgs confdev;
        } // extraHMArgs;

        modules =
          [
            ./hosts/${hostPath}/configuration.nix
            { nixpkgs.overlays = overlays; }
          ]
          ++ (if enableHM then [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ian = {
                imports = [ ./hosts/${hostPath}/home.nix ];
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
      # 1. MAIN DESKTOP — unchanged
      ##########################################################################
      main-desktop = mkSystem {
        system = "x86_64-linux";
        hostPath = "main-desktop";
        enableHM = true;
        extraHMArgs = { confdev = confdev; };
      };

      ##########################################################################
      # 2. RASPBERRY PI 5 — using nvmd image builder correctly
      ##########################################################################
      raspberry-pi = nixos-raspberrypi.lib.nixosSystem {
        system = "aarch64-linux";

        # makes Pi modules + firmware + extlinux boot generation work
        specialArgs = inputs;

        modules = [
          # Enable Pi 5 hardware, firmware, bootloader, config.txt generation
          ({ ... }: {
            imports = with nixos-raspberrypi.nixosModules; [
              raspberry-pi-5.base
              raspberry-pi-5.bluetooth
            ];
          })

          # Your manually written config for normal system settings
          ./hosts/raspberrypi/configuration.nix
        ];
      };
    };
  };
}
