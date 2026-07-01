{
  description = "Ian's NixOS Configuration";

  /**
   ****
  Inputs
  *****
  */

  inputs = {
    /*
    unstable for flakes
    */
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    /*
    Raspberry Pi boot + firmware image builder
    */
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    /*
    Hyprland Git repo for lua support -- pin
    */
    hyprland.url = "github:hyprwm/Hyprland/v0.55.0";

    /*
    secrets
    */
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    /*
    home manager as nixos module
    */
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    /*
    old r version
    */
    r423 = {
      url = "github:NixOS/nixpkgs/nixos-23.05";
      flake = false;
    };

    /*
    overlays
    */
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    waybar-icatesdoglio.url = "git+ssh://git@github.com/icatesdoglio/Waybar";

    /*
    custom flakes
    */
    confdev.url = "git+ssh://git@github.com/icatesdoglio/confdev";
    suckless = {
      url = "git+ssh://git@github.com/icatesdoglio/suckless?submodules=1";
    };
    bemenu.url = "git+ssh://git@github.com/icatesdoglio/bemenu";
  };

  /**
   *****
  Outputs
  ******
  */

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-raspberrypi,
    hyprland,
    sops-nix,
    home-manager,
    r423,
    neovim-nightly-overlay,
    waybar-icatesdoglio,
    confdev,
    suckless,
    bemenu,
    ...
  }: let
    overlays = [
      (import neovim-nightly-overlay)
      (_final: prev: {
        citrix-workspace = prev.citrix-workspace.overrideAttrs (old: {
          version = "26.04.0.105";
          src = prev.requireFile {
            name = "linuxx64-gcc-8-26.04.0.105.tar.gz";
            sha256 = "1aqqi0slms2qyq7qh4zgaj24896s9al1rvy1avsj6clv40v71v5g";
            url = "https://www.citrix.com/downloads/workspace-app/";
          };
          autoPatchelfIgnoreMissingDeps = [
            "libwebkit2gtk-4.0.so.37"
            "libsoup-2.4.so.1"
            "libjavascriptcoregtk-4.0.so.18"
          ];
        });
      })
      (final: prev: {
        waybar = prev.waybar.overrideAttrs (old: {
          src = waybar-icatesdoglio;

          version = "0.14.0-icatesdoglio";

          patches =
            (old.patches or [])
            ++ [
              (builtins.toFile "waybar-hyprland-lua-workspaces.patch" ''
                diff --git a/src/modules/hyprland/workspace.cpp b/src/modules/hyprland/workspace.cpp
                index 83fb7d5..a2ab392 100644
                --- a/src/modules/hyprland/workspace.cpp
                +++ b/src/modules/hyprland/workspace.cpp
                @@ -70,11 +70,8 @@ bool Workspace::handleClicked(GdkEventButton *bt) const {
                   if (bt->type == GDK_BUTTON_PRESS) {
                     try {
                       if (id() > 0) {  // normal
                -        if (m_workspaceManager.moveToMonitor()) {
                -          m_ipc.getSocket1Reply("dispatch focusworkspaceoncurrentmonitor " + std::to_string(id()));
                -        } else {
                -          m_ipc.getSocket1Reply("dispatch workspace " + std::to_string(id()));
                -        }
                +        m_ipc.getSocket1Reply("dispatch hl.dsp.focus({ workspace = " + std::to_string(id()) +
                +                              " })");
                       } else if (!isSpecial()) {  // named (this includes persistent)
                         if (m_workspaceManager.moveToMonitor()) {
                           m_ipc.getSocket1Reply("dispatch focusworkspaceoncurrentmonitor name:" + name());
              '')
            ];

          mesonFlags =
            (old.mesonFlags or [])
            ++ [
              "-Dcava=disabled"
            ];

          doInstallCheck = false;
        });
      })
    ];

    dotfiles = self;

    mkSystem = {
      system,
      hostPath,
      enableHM ? false,
      extraHMArgs ? {
        confdev = confdev;
        suckless = suckless;
        dotfiles = dotfiles;
        bemenu = bemenu;
        hyprland = hyprland;
      },
      extraModules ? [],
    }: let
      legacy = import r423 {
        system = system;
      };
    in
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs =
          {
            inherit inputs legacy nixpkgs confdev suckless;
            hostRegistry = import ./hosts/registry.nix;
          }
          // extraHMArgs;

        modules =
          [
            {nixpkgs.overlays = overlays;}
            ./users
            ./modules
            ./hosts/${hostPath}
            sops-nix.nixosModules.sops
          ]
          ++ extraModules
          ++ (
            if enableHM
            then [
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ian = {
                  imports = [./home ./hosts/${hostPath}/home.nix];
                  _module.args = extraHMArgs // {inherit legacy;};
                };
              }
            ]
            else []
          );
      };
  in {
    /**
     ******
     SYSTEMS
    *******
    */
    nixosConfigurations = {
      /**
       **************
       1. MAIN DESKTOP
      ****************
      */
      gp-linux = mkSystem {
        system = "x86_64-linux";
        hostPath = "gp-linux";
        enableHM = true;
      };

      /**
       ****************************
       Framework Laptop
      *****************************
      */
      framework = mkSystem {
        system = "x86_64-linux";
        hostPath = "framework";
        enableHM = true;
      };

      /**
       *******************************************
       3. RASPBERRY PI 5 — using nvmd image builder
      *********************************************
      */
      ServeMato = nixos-raspberrypi.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = inputs // {hostRegistry = import ./hosts/registry.nix;};

        modules = [
          ({...}: {
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
