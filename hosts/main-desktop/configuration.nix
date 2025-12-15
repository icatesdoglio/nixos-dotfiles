{ config, lib, pkgs, ... }:


{
imports = [ 
./hardware-configuration.nix 
../shared/common.nix
];
networking = {
    hostName = "gp-linux";

    networkmanager = {
      enable = true;
      ensureProfiles.profiles."lan-static" = {
        connection = {
          id = "lan-static";
          type = "ethernet";
          interface-name = "enp6s0";
          autoconnect = true;
        };
        ipv4 = {
          method = "manual";
          addresses = "192.168.0.20/24";
          gateway = "192.168.0.1";
          dns = "192.168.0.1;1.1.1.1";
        };
        ipv6.method = "ignore";
      };
    };
    wireguard.interfaces.wg0 = {
      ips = [ "10.100.0.2/24" ];
      privateKeyFile = "/etc/wireguard/desktop.key";

      peers = [
      {
        publicKey = "Cc+IKGfzGNfcS4/InZY89EBtPvXydjs4Ae5/AgBmq0Y=";
        endpoint = "192.168.0.30:51820";
        allowedIPs = [ "10.100.0.0/24" ];
        persistentKeepalive = 25;
      }
      ];
    };

    firewall.interfaces.wg0.allowedTCPPorts = [ 22 ];
};

fileSystems."/boot/windows" = {
  device = "/dev/disk/by-partuuid/cfa885dc-11c0-435e-aef0-31eaca328470";
  fsType = "vfat";
  options = [ "umask=0000" ];
};

fileSystems."/boot/efi/microsoft" = {
  device = "/boot/windows/efi/microsoft";
  fsType = "none";
  options = [ "bind" ];
};

boot.loader = {
  systemd-boot = {
    enable = true;
    extraEntries = {
      "windows.conf" = ''
        title Windows 11
        efi /EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };

  efi.canTouchEfiVariables = true;
};

boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

systemd.services.systemd-binfmt.enable = true;


services = {
  xserver.videoDrivers = [ "nvidia" ];
  pipewire = {
    enable = true;
    pulse.enable = true;
  };
  greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --greeting 'welcome' --cmd hyprland";
        user = "ian";
      };
    };
  };
  openssh.listenAddresses = [
  {
    addr = "10.100.0.2";
    port = 22;
  }
  ];
};

programs.hyprland = {
    enable = true;
    xwayland.enable = true;
};


programs.firefox.enable = true;

# nvidia settings
boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
];

nixpkgs.config.allowUnfree = true;

hardware.graphics.enable = true;

hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
};

environment.sessionVariables = {
# gbm_backend = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    NIX_OZONE_WL = "1";

    WEZTERM_SHELL_INTEGRATION = "1";

    MOZ_ENABLE_WAYLAND = "1"; 

    WLR_NO_HARDWARE_CURSORS = "1";
};

# Extra Permissions for dealing with the desktop environment
users.users.ian.extraGroups = lib.mkAfter [ "video" "audio" "networkmanager" ];


environment.systemPackages = lib.mkAfter (with pkgs; [
    # c++ toolchain
    gcc gnumake cmake ninja clang clang-tools pkg-config gdb unzip
    gfortran

    nvidia-vaapi-driver

    foot waybar wezterm wofi hyprpaper

    cliphist wl-clipboard
    wireguard-tools
]);

fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
        nerd-fonts.inconsolata
            nerd-fonts.jetbrains-mono
    ];
};

nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    substituters = [
      "https://cache.nixos.org"
      "https://nixos-raspberrypi.cachix.org"
    ];

    extra-platforms = [ "aarch64-linux" ];

    trusted-public-keys = [
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];

    trusted-users = [ "root" "ian" ];

    secret-key-files = [
        "/etc/nix/desktop-cache.key"
    ];

    builders-use-substitutes = true;

};

swapDevices = [{
    device = "/swapfile";
    size = 8192;
}];

system.stateVersion = "25.05";

}

# vim: ts=2 sts=2 sw=2 et
