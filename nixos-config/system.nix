{ config, pkgs, lib, ... }:

with lib;

{
  ## Activate serial console
  ## FIXME: make this configureable
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  ## Use the gummiboot efi boot loader.
  ## FIXME: support legacy (non-EFI) systems
  boot.loader.gummiboot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ## Enable EFI support for grub2 package
  boot.loader.grub.efiSupport = true;

  time.timeZone = "Europe/Zurich";

  services.openssh.enable = true;
  services.ntp.servers = [ "pool.ntp.org" ];

  environment.systemPackages = with pkgs; [
     emacs24-nox config.services.snabbswitch.pkg exabgp
  ];
}
