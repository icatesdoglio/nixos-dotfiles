{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.hm.programs.obsidian;
  syncScript = pkgs.writeShellApplication {
    name = "obsidian-vault-sync";
    runtimeInputs = with pkgs; [
      coreutils
      git
    ];
    text = ''
      set -euo pipefail

      repo=${lib.escapeShellArg cfg.sync.repoDir}
      commit_prefix=${lib.escapeShellArg cfg.sync.commitMessage}
      lock_dir="''${XDG_RUNTIME_DIR:-/tmp}/obsidian-vault-sync.lock"

      if ! mkdir "$lock_dir" 2>/dev/null; then
          echo "obsidian-vault-sync: another sync is already running"
          exit 0
      fi
      trap 'rmdir "$lock_dir"' EXIT

      if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          echo "obsidian-vault-sync: $repo is not a git repository" >&2
          exit 1
      fi

      git -C "$repo" pull --rebase --autostash
      git -C "$repo" add -A

      if git -C "$repo" diff --cached --quiet; then
          echo "obsidian-vault-sync: no changes"
          exit 0
      fi

      git -C "$repo" commit -m "$commit_prefix: $(date --iso-8601=seconds)"
      git -C "$repo" push
    '';
  };
in {
  options.my.hm.programs.obsidian = {
    enable = lib.mkEnableOption "Obsidian development workflow";

    vaultDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/vaults/dev";
      description = "Development note vault path.";
    };

    stochhedgeRepo = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/StochHedge";
      description = "Local StochHedge checkout used by note helpers.";
    };

    sync = {
      enable = lib.mkEnableOption "automatic Git sync for the Obsidian vault repository";

      repoDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/vaults";
        description = "Git repository that contains Obsidian vaults.";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "10m";
        description = "systemd OnUnitActiveSec interval for automatic vault sync.";
      };

      commitMessage = lib.mkOption {
        type = lib.types.str;
        default = "vault sync";
        description = "Commit message prefix for automatic vault sync commits.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      obsidian
      marksman
      glow
      syncScript
    ];

    home.sessionVariables = {
      OBSIDIAN_DEV_VAULT = cfg.vaultDir;
      STOCHHEDGE_REPO = cfg.stochhedgeRepo;
    };

    home.activation.createDevNoteVault = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p \
        ${lib.escapeShellArg cfg.vaultDir}/Daily \
        ${lib.escapeShellArg cfg.vaultDir}/Inbox \
        ${lib.escapeShellArg cfg.vaultDir}/Repos \
        ${lib.escapeShellArg cfg.vaultDir}/Decisions \
        ${lib.escapeShellArg cfg.vaultDir}/Snippets \
        ${lib.escapeShellArg cfg.vaultDir}/Templates
    '';

    home.activation.ensureVaultGitignore = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${lib.escapeShellArg cfg.sync.repoDir}
      $DRY_RUN_CMD touch ${lib.escapeShellArg cfg.sync.repoDir}/.gitignore
      if ! grep -qxF '.obsidian' ${lib.escapeShellArg cfg.sync.repoDir}/.gitignore; then
        $DRY_RUN_CMD sh -c 'echo .obsidian >> ${lib.escapeShellArg cfg.sync.repoDir}/.gitignore'
      fi
      if ! grep -qxF '.trash/' ${lib.escapeShellArg cfg.sync.repoDir}/.gitignore; then
        $DRY_RUN_CMD sh -c 'echo .trash/ >> ${lib.escapeShellArg cfg.sync.repoDir}/.gitignore'
      fi
      if ! grep -qxF '.DS_Store' ${lib.escapeShellArg cfg.sync.repoDir}/.gitignore; then
        $DRY_RUN_CMD sh -c 'echo .DS_Store >> ${lib.escapeShellArg cfg.sync.repoDir}/.gitignore'
      fi
    '';

    systemd.user.services.obsidian-vault-sync = lib.mkIf cfg.sync.enable {
      Unit = {
        Description = "Sync Obsidian vaults with Git";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${syncScript}/bin/obsidian-vault-sync";
      };
    };

    systemd.user.timers.obsidian-vault-sync = lib.mkIf cfg.sync.enable {
      Unit.Description = "Periodically sync Obsidian vaults with Git";

      Timer = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.sync.interval;
        Unit = "obsidian-vault-sync.service";
        Persistent = true;
      };

      Install.WantedBy = ["timers.target"];
    };

    programs.bash = {
      shellAliases = {
        notes = "cd ${lib.escapeShellArg cfg.vaultDir}";
        stochhedge = "cd ${lib.escapeShellArg cfg.stochhedgeRepo}";
        vault-sync = "systemctl --user start obsidian-vault-sync.service";
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
