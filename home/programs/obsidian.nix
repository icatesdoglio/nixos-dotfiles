{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.hm.programs.obsidian;
in {
  options.my.hm.programs.obsidian = {
    enable = lib.mkEnableOption "Obsidian development workflow";

    vaultDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/notes/dev";
      description = "Development note vault path.";
    };

    stochhedgeRepo = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/StochHedge";
      description = "Local StochHedge checkout used by note helpers.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      obsidian
      marksman
      glow
    ];

    home.sessionVariables = {
      OBSIDIAN_DEV_VAULT = cfg.vaultDir;
      STOCHHEDGE_REPO = cfg.stochhedgeRepo;
    };

    programs.bash = {
      shellAliases = {
        notes = "cd ${lib.escapeShellArg cfg.vaultDir}";
        stochhedge = "cd ${lib.escapeShellArg cfg.stochhedgeRepo}";
      };

      initExtra = ''
        _dev_note_open() {
            local file="$1"
            shift

            mkdir -p "$(dirname "$file")"

            if [[ ! -e "$file" ]] && [[ "$#" -gt 0 ]]; then
                printf '%s\n' "$@" > "$file"
            fi

            "''${EDITOR:-nvim}" "$file"
        }

        today() {
            local day
            day="$(date +%F)"
            _dev_note_open "${cfg.vaultDir}/Daily/$day.md" \
                "---" \
                "type: daily" \
                "date: $day" \
                "tags: [daily, dev]" \
                "---" \
                "" \
                "# $day" \
                "" \
                "## Focus" \
                "" \
                "## Notes" \
                "" \
                "## Follow-up"
        }

        devnote() {
            _dev_note_open "${cfg.vaultDir}/Inbox/dev.md" \
                "---" \
                "type: inbox" \
                "tags: [dev]" \
                "---" \
                "" \
                "# Dev Inbox" \
                "" \
                "## Capture"
        }

        projnote() {
            local repo_path
            repo_path="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

            local name="''${1:-$(basename "$repo_path")}"
            if [[ "$name" == "stochhedge" || "$name" == "StochHedge" ]]; then
                name="StochHedge"
                repo_path="${cfg.stochhedgeRepo}"
            fi

            _dev_note_open "${cfg.vaultDir}/Repos/$name.md" \
                "---" \
                "type: repo" \
                "repo: $repo_path" \
                "tags: [dev, repo]" \
                "---" \
                "" \
                "# $name" \
                "" \
                "## Current Context" \
                "" \
                "## Decisions" \
                "" \
                "## Commands" \
                "" \
                "## Links"
        }

        stochhedge-note() {
            _dev_note_open "${cfg.vaultDir}/Repos/StochHedge.md" \
                "---" \
                "type: repo" \
                "repo: ${cfg.stochhedgeRepo}" \
                "tags: [dev, stochhedge, databricks, stochastic-modeling]" \
                "---" \
                "" \
                "# StochHedge" \
                "" \
                "## Current Context" \
                "" \
                "## Active Thread" \
                "" \
                "## Decisions" \
                "" \
                "## Validation Backlog" \
                "" \
                "## Commands" \
                "" \
                "## Source Links" \
                "- ${cfg.stochhedgeRepo}/CLAUDE.md" \
                "- ${cfg.stochhedgeRepo}/docs/state_of_work.md" \
                "- ${cfg.stochhedgeRepo}/BACKLOG.md"
        }

        obsidian-dev() {
            obsidian "${cfg.vaultDir}" "$@"
        }
      '';
    };
  };
}
