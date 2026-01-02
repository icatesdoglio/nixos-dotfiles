{ config, lib, ... }:

lib.mkIf (config.my.host.role == "server") {

    services.cloudflared.tunnels.dns = {
        default = "dns";
        credentialsFile = "/etc/cloudflared/dns.json";
    };
}

