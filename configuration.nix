{ config, lib, pkgs, ... }:


{
imports = [ 
./hardware-configuration.nix 
];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "GP-linux";
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
			  command = "${pkgs.tuigreet}/bin/tuigreet --time --greeting 'Welcome' --cmd Hyprland";
			  user = "ian";
		  };
	  };
  };

  programs.firefox.enable = true;

  virtualisation.docker = {
      enable = true;
  };

  # NVIDIA settings ?
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
      # GBM_BACKEND = "nvidia-drm";
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
      # C++ toolchain
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



  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

}

