{
  lib,
  config,
  pkgs,
  dotfiles,
  ...
}: let
  cfg = config.my.hm.programs.tmux;
in {
  options.my.hm.programs.tmux.enable =
    lib.mkEnableOption "tmux configuration";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.tmux];

    # Config lives in config/tmux/tmux.conf rather than generated via
    # programs.tmux.* options, so it can be edited/reloaded directly.
    home.file.".config/tmux/tmux.conf" = {
      source = dotfiles + "/config/tmux/tmux.conf";
      force = true;
    };

    # tmux checks ~/.tmux.conf before $XDG_CONFIG_HOME/tmux/tmux.conf, and
    # only falls back to the XDG path if XDG_CONFIG_HOME is actually set in
    # the environment it starts from. That's not guaranteed here, so point
    # ~/.tmux.conf at the real config to make it unconditional.
    home.file.".tmux.conf" = {
      text = "source-file ~/.config/tmux/tmux.conf\n";
      force = true;
    };
  };
}
