{
  users.users.ian = {
    isNormalUser = true;
    group = "ian";
    extraGroups = ["wheel" "networkmanager" "vpnctl" "media"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO94PCjlZZQOajkBrVSLSNUrCXFjVeUOfYXJCZWJvxJO"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcHKU9bfS/5pjGDR7G/tTXp3NVNhg56JOh/6u+zhBXJ ian@framework"
    ];
  };

  users.groups.ian = {};
}
