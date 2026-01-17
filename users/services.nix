{ config, lib, pkgs, ... }:

{
    users.groups.qbit = {
        gid = 991;
    };

    users.users.qbit = {
        isSystemUser = true;
        uid = 991;
        group = "qbit";
        home = "/srv/qbit";
        createHome = true;
    };

}

