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

  };
}
