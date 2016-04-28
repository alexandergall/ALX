{ config, lib, pkgs, ... }:

{
  imports = [ ./interfaces.nix ];

  networking.firewall = {
    enable = true;
    allowPing = true;
  };

}
