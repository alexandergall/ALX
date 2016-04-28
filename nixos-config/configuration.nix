{ config, pkgs, lib, ... }:

with lib;

{
  imports =
    [ ./system.nix
      ./hardware-configuration.nix
      ./networking
      ./users.nix
      ./snmpd.nix
      ./bgp.nix
      ./l2vpn.nix
    ];
}
