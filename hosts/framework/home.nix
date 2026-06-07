{
  my.hm.desktop.hyprland.enable = true;
  my.hm.desktop.dwm.enable = true;
  my.hm.desktop.plasma.enable = true;

  my.hm.programs = {
    git.enable = true;
    neovim.enable = true;
    wezterm.enable = true;
    ssh.enable = true;
    river.enable = true;
    confdev.enable = true;
    obsidian = {
      enable = true;
      sync.enable = true;
    };
  };

  programs.bash.enable = true;

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  my.games = {
    minecraft.enable = false;
  };

  my.hm.packages = {
    enable = true;
  };
}
