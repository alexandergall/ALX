### Template for the configuraion of the installer. Copy
### a customized version of this file to "installer-config.nix".

{ config, pkgs, lib, ... }:

with lib;

{
  nfsroot.bootLoader = {

    ## Set the interfaces used during PXE boot.

    ## GRUB refers to network interfaces by names of the form
    ## efinet<n>, where <n> is a number starting from 0.  It is
    ## unclear, how the numbers are assigned.  The boot loader
    ## displays the list of available interfaces when it starts up.
    ## The setting "efinetDHCPInterface" designates the interface on
    ## which GRUB will perform DHCP to discover the TFTP server from
    ## which it will fetch the kernel with the fixed path
    ## /nixos/bzImage.  It defaults to "efinet0".
    efinetDHCPInterface = "efinet0";

    ## Once the kernel is loaded, it is started with the option
    ## "root=/dev/nfs" to initiate a boot with the root file system
    ## provided over NFS.  The kernel must perform another DHCP
    ## request to find the location (server and path) of the root file
    ## system.  This is triggered by the "ip" boot option.  To avoid
    ## probing all interfaces on a multi-homed host, the name of the
    ## interface is passed to the kernel by the boot loader as
    ## "ip=:::::<if>:dhcp::", where <if> is the name of the same
    ## interface as above but this time in the kernel's namespace,
    ## e.g. "eth0".  This name needs to be set by the following
    ## option, which defaults to "eth0".
    linuxPnPInterface = "eth0";

  };
}
