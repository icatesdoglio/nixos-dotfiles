{
  programs.bash = {
    enable = true;

    historySize = 10000;
    historyFileSize = 100000;
    historyControl = ["ignoredups" "erasedups"];

    shellOptions = ["histappend" "extglob" "globstar" "checkjobs"];

    initExtra = ''
        _prompt_git_branch() {
            local branch
                branch="$(git branch --show-current 2>/dev/null)" || return
                [[ -z "$branch" ]] && return

                printf '(%s)' "$branch"
        }

    PS1='\[\e[38;2;122;162;247m\][\u@\h \w]\[\e[38;2;194;139;44m\]$(_prompt_git_branch)\[\e[38;2;158;206;106m\]\$\[\e[0m\] '
        '';
  };
}
