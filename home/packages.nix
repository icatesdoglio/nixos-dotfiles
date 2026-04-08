{
  lib,
  config,
  pkgs,
  legacy,
  confdev,
  ...
}: let
  cfg = config.my.hm.packages;
in {
  #################################
  # Options
  #################################

  options.my.hm.packages = {
    enable = lib.mkEnableOption "Home package set";

    cli.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Basic CLI utilities";
    };

    dev.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "General development tools";
    };

    cpp.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "C/C++ toolchain";
    };

    nix.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Nix language tooling";
    };

    r.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "R environment";
    };

    bluetooth.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Bluetui mostly";
    };

    custom.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Custom user tooling";
    };
  };

  #################################
  # Config
  #################################

  config = lib.mkIf cfg.enable {
    home.packages =
      #################################
      # CLI
      #################################
      lib.optionals cfg.cli.enable (with pkgs; [
        ripgrep
        fd
        jq
        tree
        htop
        wget
        curl
        tmux
        zoxide
        starship
        sops
        yazi
        fzf
      ])
      #################################
      # Dev
      #################################
      ++ lib.optionals cfg.dev.enable (with pkgs; [
        uv
        python313
        pyright
        rustup
        nodejs
        lua-language-server
        claude-code
        databricks-cli
        slack
        # zoom-us
      ])
      #################################
      # C / C++
      #################################
      ++ lib.optionals cfg.cpp.enable (with pkgs; [
        gcc
        gnumake
        cmake
        ninja
        clang-tools
        pkg-config
        gdb
        unzip
      ])
      #################################
      # Nix
      #################################
      ++ lib.optionals cfg.nix.enable (with pkgs; [
        nixd
        alejandra
        statix
        deadnix
      ])
      #################################
      # R
      #################################
      ++ lib.optionals cfg.r.enable [
        pkgs.R
        (pkgs.writeShellScriptBin "R42" ''
          exec ${legacy.rWrapper}/bin/R "$@"
        '')
      ]
      #################################
      # bluetooth
      #################################
      ++ lib.optionals cfg.bluetooth.enable (with pkgs; [
        bluetui
      ]);

    /**
       #################################
    # Custom
    #################################
    ++ lib.optionals cfg.custom.enable [
      (confdev.packages.${pkgs.system}.default)
    ];
    */
  };
}
