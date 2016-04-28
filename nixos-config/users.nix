{ config, pkgs, lib, ... }:

with lib;

{
  ## Force all user-related configuration to be derived from
  ## the NixOS configuration.  All manual changes will be
  ## lost after "nixos-rebuild".
  users.mutableUsers = false;
  ## The default root password is "root".  It can only be used
  ## to log in via the console.
  users.extraUsers.root.hashedPassword = "$6$cSUnFL6MbD34$BaS0NLN1KCddegCaTKDMCc1D21Pdge9gFz5tr65U0KgNOgtrEoAGuVnelaPIuEb7iC0FOWE7HUG6NV2b2yN8s/";

  ## Add user accounts and sudo configuration here.
  ##
  ## users.extraUsers.foo = {
  ##   isNormalUser = true;
  ##    uid = 1000;
  ##   openssh.authorizedKeys.keys = [ "ssh-dss AAAAB3NzaC1k..." ];
  ## };

  ## security.sudo.extraConfig =
  ##  ''
  ##    foo ALL=(ALL:ALL) NOPASSWD: ALL
  ##  '';
}
