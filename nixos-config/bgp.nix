{ config, pkgs, lib, ... }:

with lib;

{
  services.exabgp.enable = false;
}
