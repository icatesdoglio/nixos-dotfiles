{
  users.users.michelle = {
    isNormalUser = true;
    group = "michelle";
    extraGroups = ["wheel" "networkmanager" "vpnctl" "media"];
  };

  users.groups.michelle = {};

  # Auto-launch Plasma on TTY1 login instead of making her run startx/dwm/Hyprland
  # by hand like the other users on these hosts. Requires my.desktop.plasma.enable
  # on every host she logs into.
  environment.loginShellInit = ''
    if [ "$(whoami)" = "michelle" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec dbus-run-session startplasma-wayland
    fi
  '';
}
