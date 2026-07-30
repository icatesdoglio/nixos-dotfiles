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
      (final: prev: {
        zoom-us = final.callPackage ./app/zoom-us.nix {};
      })
      (final: prev: {
        databricks-cli = prev.databricks-cli.overrideAttrs (old: rec {
          version = "1.9.0";
          src = prev.fetchurl {
            url = "https://github.com/databricks/cli/archive/v${version}.tar.gz";
            hash = "sha256-TxbqPh57rVjEHc6qU9CzBNz5HP3jX3Ip9B7TbDb3DpE=";
          };
          vendorHash = "";
          ldflags = final.lib.unique (
            (old.ldflags or [])
            ++ [
              "-X github.com/databricks/cli/internal/build.buildVersion=${version}"
            ]
          );
        });
      })
      (_final: prev: {
        citrix-workspace = (prev.citrix-workspace.override {
          extraCerts = [
            (prev.writeText "DigiCertGlobalG2TLSRSASHA2562020CA1.pem" ''
              -----BEGIN CERTIFICATE-----
              MIIEyDCCA7CgAwIBAgIQDPW9BitWAvR6uFAsI8zwZjANBgkqhkiG9w0BAQsFADBh
              MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
              d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBH
              MjAeFw0yMTAzMzAwMDAwMDBaFw0zMTAzMjkyMzU5NTlaMFkxCzAJBgNVBAYTAlVT
              MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxMzAxBgNVBAMTKkRpZ2lDZXJ0IEdsb2Jh
              bCBHMiBUTFMgUlNBIFNIQTI1NiAyMDIwIENBMTCCASIwDQYJKoZIhvcNAQEBBQAD
              ggEPADCCAQoCggEBAMz3EGJPprtjb+2QUlbFbSd7ehJWivH0+dbn4Y+9lavyYEEV
              cNsSAPonCrVXOFt9slGTcZUOakGUWzUb+nv6u8W+JDD+Vu/E832X4xT1FE3LpxDy
              FuqrIvAxIhFhaZAmunjZlx/jfWardUSVc8is/+9dCopZQ+GssjoP80j812s3wWPc
              3kbW20X+fSP9kOhRBx5Ro1/tSUZUfyyIxfQTnJcVPAPooTncaQwywa8WV0yUR0J8
              osicfebUTVSvQpmowQTCd5zWSOTOEeAqgJnwQ3DPP3Zr0UxJqyRewg2C/Uaoq2yT
              zGJSQnWS+Jr6Xl6ysGHlHx+5fwmY6D36g39HaaECAwEAAaOCAYIwggF+MBIGA1Ud
              EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFHSFgMBmx9833s+9KTeqAx2+7c0XMB8G
              A1UdIwQYMBaAFE4iVCAYlebjbuYP+vq5Eu0GF485MA4GA1UdDwEB/wQEAwIBhjAd
              BgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwdgYIKwYBBQUHAQEEajBoMCQG
              CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQAYIKwYBBQUHMAKG
              NGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RH
              Mi5jcnQwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybDMuZGlnaWNlcnQuY29t
              L0RpZ2lDZXJ0R2xvYmFsUm9vdEcyLmNybDA9BgNVHSAENjA0MAsGCWCGSAGG/WwC
              ATAHBgVngQwBATAIBgZngQwBAgEwCAYGZ4EMAQICMAgGBmeBDAECAzANBgkqhkiG
              9w0BAQsFAAOCAQEAkPFwyyiXaZd8dP3A+iZ7U6utzWX9upwGnIrXWkOH7U1MVl+t
              wcW1BSAuWdH/SvWgKtiwla3JLko716f2b4gp/DA/JIS7w7d7kwcsr4drdjPtAFVS
              slme5LnQ89/nD/7d+MS5EHKBCQRfz5eeLjJ1js+aWNJXMX43AYGyZm0pGrFmCW3R
              bpD0ufovARTFXFZkAdl9h6g4U5+LXUZtXMYnhIHUfoyMo5tS58aI7Dd8KvvwVVo4
              chDYABPPTHPbqjc1qCmBaZx2vN4Ye5DUys/vZwP9BFohFrH/6j/f3IL16/RZkiMN
              JCqVJUzKoZHm1Lesh3Sz8W2jmdv51b2EQJ8HmA==
              -----END CERTIFICATE-----
            '')
          ];
        }).overrideAttrs (old: {
          version = "26.04.0.105";
          src = prev.requireFile {
            name = "linuxx64-26.04.0.105.tar.gz";
            sha256 = "1kl6b1ldjd9gb6cmvhxf6ggvc3amq1kz0qwjlb1fp6dxx0pivwm8";
            url = "https://www.citrix.com/downloads/workspace-app/";
          };
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
