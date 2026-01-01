{
  users.users.ian = {
    isNormalUser = true;
    group = "ian";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBtghfDdBX+s+XnZbnP3kiV83dCVymSO4Zhv/SudP8pS"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO94PCjlZZQOajkBrVSLSNUrCXFjVeUOfYXJCZWJvxJO"
    ];
  };

  users.groups.ian = {};
}

