{ config, lib, ... }:

let
  hashFor = name: builtins.getEnv "${lib.toUpper name}_INITIAL_HASH";
  names = [ "root" ] ++ (map (u: u.name) config.mySystem.users);
in
{
  users.mutableUsers = true;
  security.sudo.wheelNeedsPassword = true;

  assertions = map (name: {
    assertion = hashFor name != "";
    message = "${lib.toUpper name}_INITIAL_HASH is empty — source secrets/initial-passwords.env before building";
  }) names;

  users.users = (lib.listToAttrs (map (u: lib.nameValuePair u.name {
    isNormalUser = true;
    extraGroups = lib.optionals u.wheel [ "wheel" ];
    initialHashedPassword = hashFor u.name;
  }) config.mySystem.users)) // {
    root.initialHashedPassword = hashFor "root";
  };
}
