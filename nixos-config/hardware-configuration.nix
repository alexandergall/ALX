## This file will be overwritten by "nixos-generate-config" on a
## freshly installed system.  It is used, however, when creating the
## system closure to put in the install image.  This will make sure
## that certain packages needed to activate the configuration on a
## newly installed system will already be in the Nix store.

{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "sd_mod" ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
