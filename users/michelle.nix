{
  users.users.michelle = {
    isNormalUser = true;
    group = "michelle";
    extraGroups = ["wheel" "networkmanager" "vpnctl" "media"];
  };

  users.groups.michelle = {};
}
