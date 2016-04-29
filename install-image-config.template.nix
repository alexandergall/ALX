### Template for the configuraion of the install image. Copy
### a customized version of this file to "install-image-config.nix".

{ config, pkgs, lib, ... }:

with lib;

{
  installImage = {

    ## This device will be partitioned and formatted unconditionally
    ## on the install target.  Currently, this process is minimalistic
    ## and not configurable.  Two partitions will be created. The
    ## first is a 512MiB EFI boot partition (FAT32).  The second
    ## partition is of type ext4 and takes up the remainder of the
    ## disk.  4GiB remain unused and could be configured as swap
    ## space.
    rootDevice = "/dev/sda";

    networking = {

      ## The installer creates (overwrites) the file
      ## /etc/nixos/networking/interfaces.nix, which
      ## contains the configuration of network interfaces.
      ## By default, DHCP is enabled for all interfaces.
      useDHCP = true;

      ## The following would disable DHCP and cause the installer to create
      ## a static network configuration for the interface "enp12s0" (using the
      ## "usePredictableInterfaceNames" feature) from the information
      ## discovered via DHCP when the system is configured.
      # useDHCP = false;
      # staticInterfaceFromDHCP = "enp12s0";

    };
  };
}
