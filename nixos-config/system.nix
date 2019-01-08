{ config, pkgs, lib, ... }:

with lib;

{
  ## Activate serial console
  ## FIXME: make this configureable
  boot.kernelParams = with import ./serial-config.nix;
    [ "console=ttyS${serialUnit},${linuxConsoleConfig}" ];

  ## FIXME: support legacy (non-EFI) systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ## Enable EFI support for grub2 package
  boot.loader.grub.efiSupport = true;

  time.timeZone = "Europe/Zurich";

  services.openssh.enable = true;
  services.ntp.servers = [ "pool.ntp.org" ];

  environment.systemPackages = with pkgs; [
     emacs25-nox config.services.snabb.pkg
  ];
}
