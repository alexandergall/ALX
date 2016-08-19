{ config, pkgs, lib, ... }:

with lib;

{
  imports = [ ./devices ];

  services.snabb = {
    enable = true;
    interfaces = [];
    programs.l2vpn.instances = {};
  };
}
