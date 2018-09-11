{ config, pkgs, lib, ... }:

with lib;

{
  services.snabb = {
    enable = true;
    snmp.enable = true;
    interfaces = [];
    programs.l2vpn.instances = {};
  };
}
