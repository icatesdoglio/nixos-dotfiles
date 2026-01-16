{ config, lib, pkgs, ... }:

{
  users.groups.cloudflare-updater = {};

  users.users.cloudflare-updater = {
    isSystemUser = true;
    group = "cloudflare-updater";
  };
}

