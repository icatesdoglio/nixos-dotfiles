{
    description = "Ian's NixOS Configuration";

    /******
     Inputs
     ******/

    inputs = {

        /* unstable for flakes */
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

        /* Raspberry Pi boot + firmware image builder */
        nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

        /* secrets */
        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        /* home manager as nixos module */
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };


        /* old r version */
        r423 = {
            url = "github:NixOS/nixpkgs/nixos-23.05";
            flake = false;
        };

        /* overlays */
        neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

        /* custom flakes */
        confdev.url = "path:/home/ian/src/confdev";
        suckless.url = "path:/home/ian/src/suckless";

    };

    /*******
     Outputs
     *******/

    outputs = inputs@{
        self, 
            nixpkgs,
            nixos-raspberrypi,
            sops-nix,
            home-manager,
            r423,
            neovim-nightly-overlay,
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
                    inherit inputs legacy nixpkgs confdev suckless;
                } // extraHMArgs;


                modules = [
                    { nixpkgs.overlays = overlays; }
                    ./users
                        ./modules
                        ./hosts/${hostPath}
                        sops-nix.nixosModules.sops
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

            /********
              SYSTEMS
             ********/
            nixosConfigurations = {

                /****************
                  1. MAIN DESKTOP
                 *****************/
                gp-linux = mkSystem {
                    system = "x86_64-linux";
                    hostPath = "gp-linux";
                    enableHM = true;
                    extraHMArgs = { confdev = confdev; suckless = suckless; dotfiles = dotfiles; };
                };

		/******************************
		  Framework Laptop
		 ******************************/
		framework = mkSystem {
		system = "x86_64-linux";
		hostPath = "framework";
		enableHM = true;
		extraHMArgs = { confdev = confdev; suckless = suckless; dotfiles = dotfiles; };
		};

                /*********************************************
                  3. RASPBERRY PI 5 — using nvmd image builder
                 **********************************************/
                ServeMato = nixos-raspberrypi.lib.nixosSystem {
                    system = "aarch64-linux";
                    specialArgs = inputs;

                    modules = [
                        ({ ... }: {
                         imports = with nixos-raspberrypi.nixosModules; [
                         raspberry-pi-5.base
                         raspberry-pi-5.bluetooth
                         sops-nix.nixosModules.sops
                         ];
                         })
                    ./users
                        ./hosts/ServeMato
                        ./modules
                        ./modules/boot/raspberry-pi.nix
                    ];
                };
            };
        };
}
