{ config, lib, pkgs, ... }:


{
imports = [ 
./hardware-configuration.nix 
../../hosts/shared/common.nix
];
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

networking.hostName = "gp-linux";
networking.networkmanager.enable = true;

time.timeZone = "America/Los_Angeles";

services.xserver.videoDrivers = [ "nvidia" ];

services.pipewire = {
    enable = true;
    pulse.enable = true;
};

programs.hyprland = {
    enable = true;
    xwayland.enable = true;
};

services.greetd = {
    enable = true;
    settings = {
        default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --greeting 'welcome' --cmd hyprland";
            user = "ian";
        };
    };
};

programs.firefox.enable = true;

virtualisation.docker = {
    enable = true;
};

# nvidia settings ?
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

users.users.ian = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "docker" ];
};


environment.systemPackages = with pkgs; [
# c++ toolchain
    gcc gnumake cmake ninja clang clang-tools pkg-config gdb unzip
    gfortran
    nvidia-vaapi-driver

    vim
    wget
    foot
    waybar
    wezterm
    cliphist
    wl-clipboard
    gnupg
    wofi
    hyprpaper
];

fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
        nerd-fonts.inconsolata
            nerd-fonts.jetbrains-mono
    ];
};
nix.settings.experimental-features = [ "nix-command" "flakes" ];
system.stateVersion = "25.05";

services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "no";
};

swapDevices = [
{
    device = "/swapfile";
    size = 8192;
}
];

programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
};

}

