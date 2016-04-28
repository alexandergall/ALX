{ config, pkgs, lib, ... }:

with lib;

{
  services.snabbswitch = {
    enable = true;
    pkg = pkgs.snabbswitchVPN;
    interfaces = [];
    programs.l2vpn.instances = {};
  };
}
