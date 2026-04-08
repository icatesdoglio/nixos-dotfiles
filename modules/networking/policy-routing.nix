{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.networking.policyRouting;

  ruleType = lib.types.submodule ({...}: {
    options = {
      priority = lib.mkOption {
        type = lib.types.int;
        description = "Policy routing priority (lower = earlier).";
      };

      table = lib.mkOption {
        type = lib.types.nullOr (lib.types.oneOf [
          lib.types.str
          lib.types.int
        ]);
        default = null;
        description = "Routing table to lookup.";
      };

      to = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Destination CIDR.";
      };

      iif = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Incoming interface.";
      };

      uid = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "User or UID.";
      };

      blackhole = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Blackhole matching traffic.";
      };
    };
  });

  mkRuleCmd = rule: let
    base = "${pkgs.iproute2}/bin/ip rule add priority ${toString rule.priority}";
    match = lib.concatStringsSep " " (lib.filter (s: s != "") [
      (
        if rule.to != null
        then "to ${rule.to}"
        else ""
      )
      (
        if rule.iif != null
        then "iif ${rule.iif}"
        else ""
      )
      (
        if rule.uid != null
        then "uidrange ${rule.uid}-${rule.uid}"
        else ""
      )
    ]);
    action =
      if rule.blackhole
      then "blackhole"
      else "lookup ${toString rule.table}";
  in "${base} ${match} ${action}";

  mkDelCmd = rule: "${pkgs.iproute2}/bin/ip rule del priority ${toString rule.priority} 2>/dev/null || true";
in {
  options.my.networking.policyRouting = {
    enable = lib.mkEnableOption "custom policy routing rules";

    rules = lib.mkOption {
      type = lib.types.listOf ruleType;
      default = [];
      description = "Policy routing rules.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.policy-routing = {
      description = "Apply policy routing rules";
      wantedBy = ["network-online.target"];
      after = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -e
        ${lib.concatStringsSep "\n" (map mkRuleCmd cfg.rules)}
      '';

      preStop = ''
        ${lib.concatStringsSep "\n" (map mkDelCmd cfg.rules)}
      '';
    };
  };
}
