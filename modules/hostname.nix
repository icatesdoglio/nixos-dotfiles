{ lib, config, ... }:

with lib;

{
  options.my.host = {
    name = mkOption {
      type = types.str;
      description = "Logical host name (authoritative)";
    };

    role = mkOption {
      type = types.enum [ "desktop" "laptop" "server" ];
      default = "desktop";
      description = "Host role";
    };

    platform = mkOption {
      type = types.enum [ "x86_64" "raspberry-pi" ];
      default =
        if config.system.build.platform == "aarch64-linux"
        then "raspberry-pi"
        else "x86_64";
      description = "Hardware platform";
    };
  };

  config = {
    # Single source of truth for the system hostname
    networking.hostName = config.my.host.name;

    # Safety: every host must define a name
    assertions = [
      {
        assertion = config.my.host.name != "";
        message = "my.host.name must be set explicitly for every host";
      }
    ];
  };
}

