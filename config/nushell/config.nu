# Disable banner
$env.config.show_banner = false


# =============================================================================
# Zoxide hook configuration (fixed for Nushell 0.108+)
# =============================================================================

export-env {
  $env.config = (
      $env.config?
      | default {}
      | upsert hooks {}                  # must be a record
      | upsert hooks.env_change {}       # must be a record
      | upsert hooks.env_change.PWD []   # must be a list
  )

  # Only add the hook if it isn't already installed
  if not ($env.config.hooks.env_change.PWD | any { get __zoxide_hook? | default false }) {
      $env.config.hooks.env_change.PWD = (
          $env.config.hooks.env_change.PWD
          | append {
              __zoxide_hook: true,
              code: {|_, dir| zoxide add -- $dir }
          }
      )
  }
}

# Zoxide wrapped commands
def --env --wrapped __zoxide_z [...rest: string] {
    let path = match $rest {
        [] => '~'
        ['-' ] => '-'
        [$arg] if (($arg | path expand | path type) == 'dir') => $arg
        _ => (zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n")
    }
    cd $path
}

def --env --wrapped __zoxide_zi [...rest: string] {
    cd (zoxide query --interactive -- ...$rest | str trim -r -c "\n")
}

alias z = __zoxide_z
alias zi = __zoxide_zi

# =============================================================================

$env.config.buffer_editor = "nvim"

banner --short

def nbc [] {

      sudo nixos-rebuild switch --flake ~/nixos-dotfiles#main
}

def hbc [] {
      home-manager switch --flake ~/nixos-dotfiles#main
}
