# ALX
The Agile LAN eXtender - Providing Point-to-point and multi-point L2-VPNs on top of IP

## Motivation and Overview

This repository provides the framework to create and maintain a
full-featured network appliance based on the [Snabb
Switch](https://github.com/snabbco/snabb/blob/master/README.md)
project.  The core code used by the appliance is maintained in the
[`l2vpn` branch](https://github.com/snabbco/snabb/tree/l2vpn) of the
main [Snabb repository](https://github.com/snabbco/snabb).  Please
refer to the documentation of the [`l2vpn` Snabb
program](https://github.com/snabbco/snabb/blob/l2vpn/src/program/l2vpn/README.md)
for a detailed description of the service.

The motivation for creating the `l2vpn` application in the first place
is explained in a [short
paper](https://tnc2014.terena.org/getfile/934) and a
[presentation](https://www.youtube.com/watch?v=Jbn3aNkud6Y)
([slides](https://tnc2014.terena.org/getfile/1788)) given at the
[TERENA Network Conference 2014](https://tnc2014.terena.org/).

The `l2vpn` application is fully functional on its own (possibly
augmented with [SNMP
subagents](https://github.com/alexandergall/snabb-snmp-subagent) for
SNMP support and some kind of BGP daemon to propagate the next-hop for
routing of the tunnel endpoints) on any Linux-based system.  As such,
the operator can chose any method she wants for management and
monitoring - after all, "it's just a server".  While this seems like a
desirable feature (and it might well be so in certain environments),
it doesn't work well in a very important use-case, which is as a
"network appliance" run side-by-side with traditional appliances like
routers or switches by a regular network operation center (NOC).

The typical environment in that case looks like this: the operator
buys a device from a vendor who provides both, the hardware and the
software that runs on it.  The vendor (possibly through a re-seller)
provides well-defined "releases" of their systems as well as support
for troubleshooting.  The device itself usually has its own
configuration environment (e.g. a GUI or a specialized CLI) and
provides certain standard "northbound" interfaces for remote
monitoring and management (e.g. SNMP and/or Netconf/YANG).

In particular, the operator is not bothered with the details of the
operating system that runs on the device.  From her perspective, the
interaction with it is pretty much limited to

   * configuration of actual network services, e.g. interfaces,
     routing protocols or, for that matter, L2 VPNs

   * system maintenance, e.g. upgrade of releases or configuration
     management (backup, rollbacks etc.)

This is substantially different from running a generic server, where
the operator has to deal with every minute detail of the chosen
distribution apart from running the actual service itself.  This is
the main reason why it is difficult to integrate such a system into
the work flow of a traditional NOC.

The aim of the ALX system is to turn a generic server which happens to
be running a network-centric application into an appliance that
adheres to the same operational principles as traditional network
appliances.

Key to this is the choice of the Linux distribution and how it is
presented to the user in terms of installation and maintenance.  The
following items are of particular importance

   * Precise definition of the system, i.e. an exhaustive list of
     software packages, their versions and exact specification how to
     build them, that make up the system

   * Upgrades and rollbacks to specific system configurations that can
     be treated as well-defined "releases" of the entire system

The problem with *all* well-known Linux distributions is that none of
them can truly fulfill these requirements.  For example, package
dependencies are strictly *nominal*, e.g. they refer to the *names* of
other packages (and usually version numbers) but not how exactly they
need to be built to satisfy the requirements of the package which
depends on them.  None of them can perform a true rollback to a
previous state of the system after a major upgrade of the
distribution.

This state of affairs is the reason why the ALX project has chosen the
[NixOS](https://nixos.org/) distribution as basis for packaging the
`l2vpn` application.  This distribution is based on a purely
functional approach to package management (the [Nix package
manager](https://nixos.org/nix/)), which overcomes these shortcomings.
The interested reader is referred to the
[NixOS](https://nixos.org/nixos/manual/) and
[Nix](http://nixos.org/nix/manual/) manuals as well as the main
author's [PhD thesis](http://nixos.org/~eelco/pubs/phd-thesis.pdf) for
details.

One of the most important aspects of Nix/NixOS is the purely
declarative style of describing a particular system configuration
through an expression in a specialized (domain-specific) functional
programming language (the *Nix expression language*).  This expression
states how exactly every single piece of software that will make up
the system is to be built from source code, which makes it perfect to
use as the very definition of a specific release of the system (in
practice, a *binary cache* of pre-built packages is used to avoid
having to actually build everything from source).

It is not only the definition of packages which is purely declarative
but the entire system configuration, e.g. the configuration of all the
services, user accounts, settings etc.  This makes it possible to
replicate any system *precisely* by supplying the Nix expressions for
the packages and the configuration.

This is essentially all that is to the ALX system as such.  The
present Git repository contains a
[fork](https://github.com/alexandergall/ALX) of the [official NixOS
source distribution](https://github.com/NixOS/nixpkgs) as a submodule.
This fork contains the descriptions how to build the `l2vpn`-specific
components as well as some NixOS modules that allow configuration of
the entire system purely through Nix expressions.

The repository also contains a facility that provides a
fully-automated PXE-based installer to set up a system from scratch.

## Versioning

### NixOS standard versioning

NixOS uses version numbers in the format `<major>.<minor>.<commit>`
for its [official releases](https://nixos.org/releases/nixos/), for
example `16.03.659.011ea84`. `<major>` itself is of the form
`<year>.<month>`.  There are two major releases per year, one in March
(month `03`) and the other in September (month `09`), which are
denoted as stable releases.

The [`nixpkgs` Git repository](https://github.com/NixOS/nixpkgs)
contains a branch for each stable release called `release-<major>`,
e.g. `release-16.03`.  One particular commit on this branch is marked
as the start of the major release by the maintainers.  `<minor>`
counts the number of commits since that particular commit and
`<commit>` is the abbreviated Git commit from which the release was
created.


### ALX versioning

Because ALX is basically a plain NixOS release with a few custom
modifications, it essentially uses the same versioning method as
NixOS.  The creation of a major ALX release within the [ALX Git
repository](https://github.com/alexandergall/nixpkgs.git) proceeds as
follows.

   * Possibly sync the fork with the upstream NixOS repository
   * Checkout the NixOS release branch, e.g. `release-16.03`
   * Tag the commit with `<major>.ALX-base`, e.g. `16.03.ALX-base`
   * Create a new branch `release-<major>.ALX` from it,
     e.g. `release-16.03.ALX`
   * Commit the ALX-specific customisations, which includes appending
     `.ALX` to `.version`
   * Add a commit that sets the `<minor>` revision counter to
     zero (by adjusting a "magic number" at the top of `nixos/release.nix`)

Version numbers will then look like `<major>.ALX.<minor>.<commit>`,
where the initial `<minor>` is 0.  Revisions are created whenever a
commit is added to the `release-<major>.ALX` branch (e.g. when
ALX-specific code is modified or when the branch is synced with the
NixOS branch on which it is based).  Each commit bumps `<minor>` up by
one.

Such a modified NixOS release could be called a "branded" NixOS
release, though this nomenclature is not used by the NixOS community.

## System requirements

   * x86-64 architecture, recommended is an Intel Haswell CPU or newer
     for applications requiring high packet rates (>500k pps)
   * The following NICs are supported
     * 1GE
       * Intel 350
       * Intel 210
     * 10GE
       * Intel 82599 SFP
       * Intel 82574L
       * Intel 82571
       * Intel 82599 T3
       * Intel X540
       * Intel X520
   * UEFI firmware for installation via PXE

## Restrictions

Only IPv6 is supported as transport protocol for encapsulated Ethernet
frames, i.e. IPv6 connectivity is required between the endpoints of
any pseudowire.

IPv6 fragmentation/reassembly is not supported.  The path-MTU between
the endpoints of any pseudowire must be large enough to accommodate the
original Ethernet frame (maximum 1514 bytes if no VLAN tags are used)
plus the encapsulation overhead, which amounts to 66 bytes at the
maximum (for the L2TPv3 and GRE encapsulations), including the 14-byte
(outer) Ethernet header.

## Downloads

The official releases of the ALX system built with default settings
are [available for download](http://alx.net.switch.ch/releases/) as is
a [generic installer](http://alx.net.switch.ch/installer/) for any
kind of NixOS system.

These downloads are automatically created by a [continuous integration
system](http://hydra.net.switch.ch/) (CI) based on
[Hydra](https://nixos.org/hydra/).

## <a name="building"></a>Building

The system as well as the generic installer can be created on any
NixOS system (note that running nixpkgs on a standard Linux
distribution as described, for example,
[here](https://nixos.org/wiki/Installing_Nix_on_Debian), is not
enough).

### Installer

To build the generic installer, clone into the `installer` branch of
https://github.com/alexandergall/ALX.git

```
$ git clone --recursive -b installer https://github.com/alexandergall/ALX.git
```

and execute

```
$ nix-build
```

To customize the installer, copy `installer-config.template.nix` to
`installer-config.nix` and apply the desired configuration options
before calling `nix-build`.  Please refer to [the documentation of the
installer
module](https://github.com/alexandergall/nixos-pxe-installer/blob/master/README.md),
in particular to the sections [Setting up the
installer](https://github.com/alexandergall/nixos-pxe-installer/blob/master/README.md#setting-up-the-installer)
and [Module
configuration](https://github.com/alexandergall/nixos-pxe-installer/blob/master/README.md#module-configuration-1)
for details.

### <a name="buildingALX"></a>ALX

To build a particular ALX release, clone into the corresponding branch of https://github.com/alexandergall/ALX.git, e.g.

```
$ git clone --recursive -b release-16.03.ALX https://github.com/alexandergall/ALX.git
```

To build the command needed for upgrading an existing ALX installation to the new version execute

```
$ nix-build -A upgradeCommand
[output suppressed]
building path(s) ‘/nix/store/z48624yyf842y4qkbslnffbm1pnnbfja-nixos-16.03.ALX.0.761972f’
/nix/store/z48624yyf842y4qkbslnffbm1pnnbfja-nixos-16.03.ALX.0.761972f
```

This creates a store derivation (a directory in `/nix/store` which
contains the result of the build) which contains a shell script

```
$ ls -l /nix/store/z48624yyf842y4qkbslnffbm1pnnbfja-nixos-16.03.ALX.0.761972f
total 7064
-r-xr-xr-x 1 root root 7229720 Jan  1  1970 alx-upgrade
```

that can be executed on the appliance to [upgrade it to this
release](#upgrading)

To build the files needed for an automated installation of a new system, execute

```
$ nix-build -A installImage -A installConfig
[output suppressed]
/nix/store/3px3vm4gvqk2s8sfq00vmk1159lnwaxp-install-tarball-nixos-16.03.ALX.0.761972f
/nix/store/7fym30dgr33xyss5aa9zvlrmb9sxjf5k-install-config
```

The resulting files are used to [install a system from
scratch](#installFromScratch).

The Snabb-specific manpage describing the NixOS configuration options
can be obtained by

```
$ nix-build module-manpage.nix -A snabb && man result/share/man/man5/configuration.nix.5
```

## Bootstrapping

There are a number of ways to get an initial installation deployed on
a system.

### <a name="installFromExistingNixOS"></a>From an existing NixOS installation

If the target system is already running NixOS, it can be transformed
into an ALX system as follows.

   * Remove the existing `nixos` channel

     ```
     # nix-channel --remove nixos
     ```
   * Add the "branded" ALX `nixos` channel, e.g. for the `16.03.ALX` major release

     ```
     # nix-channel --add file:///ALX/channels/nixos-16.03.ALX nixos
     ```
   * Merge `/etc/nixos` with the contents of the `nixos-config` directory of the
     ALX Git repository
   * Proceed as for an [upgrade](#upgrading). In this case, the upgrade command
     will fail with an error saying that `nixpkgs not available, can't compare
     versions.  Use -f to force installation`.  This is because
     `nix-channel --remove nixos` has effectively removed the nixpkgs sources
     from the standard search path (`NIX_PATH`).  Use `alx-upgrade -f` to
     force the upgrade as instructed.

### <a name="installFromScratch"></a>From scratch

If the target system has no operating system installed yet or if the
existing system should be overwritten by ALX, you have the choice of
performing a fully automated install of the ALX system directly or to
go through a standard NixOS installation first.

Once the system is installed, it is only accessible via the serial
console by logging in as `root` with password `root` (assuming the
standard NixOS configuration from the `nixos-config` directory of the
ALX Git repository was used to generate the install image).

#### Fully automated install

To perform a fully automated installation, either [build the installer
and ALX install image yourself](#building) or get the following files

   * From http://alx.net.switch.ch/installer/
      * `bootx64.efi`
      * `bzImage`
      * `nfsroot.tar.xz`
   * From http://alx.net.switch.ch/releases/ within the directory of the
     desired release (e.g. http://alx.net.switch.ch/releases/16.03.ALX/nixos-16.03.ALX.0.761972f/)
      * `nixos.tar.gz`
      * `config`

Set up DHCP, TFP and NFS servers as described in the [installer
instructions](https://github.com/alexandergall/nixos-pxe-installer/blob/master/README.md#configuring).

Then [stage the install image and
configuration](https://github.com/alexandergall/nixos-pxe-installer/blob/master/README.md#staging)
by copying `nixos.tar.gz` and `config` into the `installer` directory
of the NFS root file system and creating a symbolic link `nixos-image`
pointing to `nixos.tar.gz`, e.g. assuming the root file system is
located at `/srv/nixos/nfsroot`

```
# cp /path-to/nixos.tar.gz /src/nixos/nfsroot/installer
# cp /path-to/config /src/nixos/nfsroot/installer
# ln -s ./nixos.tar.gz /srv/nixos/nfsroot/installer/nixos-image
```

The system will be installed after performing a PXE network boot off
the DHCP configuration.

In the default configuration, the Grub boot loader `bootx64.efi`
expects to be able to boot from the NIC referred to as `efinet0` and
the Linux kernel will perform its DHCP request and NFS mount operation
over device `eth0`.  If you have a multi-homed host and need to select
different interfaces (or your system uses different assignments of
interface names), you can either generate a customized boot loader as
described in one of the [installer
examples](https://github.com/alexandergall/nixos-pxe-installer/blob/master/README.md#examples-1)
or you can download the files

  * `grub.cfg`
  * `generate`

from http://alx.net.switch.ch/installer/ and [generate `bootx64.efi` manually](https://github.com/alexandergall/nixos-pxe-installer/blob/master/README.md#updating-the-grub-boot-loader-manually)



#### Via a standard NixOS installation

Please refer to the [standard method for installing a fresh NixOS
system](https://nixos.org/nixos/download.html).  Note that this
currently involves some manual steps.  Once the system is up and
running, proceed as described in the procedure for [converting an
existing NixOS system](#installFromExistingNixOS)

## <a name="upgrading"></a>Upgrading

To upgrade an existing ALX installation to a new version, either
download the file `alx-upgrade` from the directory of the desired
target version on http://alx.net.switch.ch/releases/
(e.g. http://alx.net.switch.ch/releases/16.03.ALX/nixos-16.03.ALX.0.761972f/alx-upgrade)
or [build it yourself](#buildingALX) then copy it to an arbitrary
location on the system that should be upgraded.

The file is a shell script that contains a self-extracting archive of
the ALX-branded NixOS "channel" which, in turn, contains the Nix
expression that describes the components of the ALX system
corresponding to the new version.  The upgrade process essentially
performs an update of the channel via `nix-channel --update` followed
by `nixos-rebuild switch` to build the new system configuration and
make it the default boot environment.

Note that the upgrade command only contains the Nix expression of the
system, not any software packages.  Actual packages are fetched from
the binary cache or built from source when `nixos-rebuild` is executed.

To check the versions of the current system and the one contained in
the upgrade, execute

```
$ ./alx-upgrade -i
```

To perform the actual upgrade, execute

```
# ./alx-upgrade
```

as root.  To force an "upgrade" to a version that is actually lower
than the currently installed version, use

```
# ./alx-upgrade -f
```

To perform a rollback to the previous version, execute

```
# nix-env -p /nix/var/nix/profiles/per-user/root/channels --rollback
```

## Configuration

The system is configured exclusively through the Nix expressions
imported by `/etc/nixos/configuration.nix` (other files are included
via the `imports` list).

The configuration is strictly declarative, which means that the entire
system state is constructed from these expressions alone and does not
depend on any other inputs.  As a consequence, the system can be
reproduced exactly by installing the given ALX channel together with
the contents of `/etc/nixos`.

For convenience, the configuration is split up into separate files,
which are imported by `/etc/nixos/configuration.nix`.  The following
sections cover each of these files.

Editing the configuration has no direct effect.  A configuration is
activated by executing `nixos-rebuild` (as root).  Refer to the
`nixos-rebuild(8)` man page for a description of available options and
arguments.

The system can be rolled back to the previous configuration by using
the `--rollback` switch.  Note that this will not revert any changes
made to the configuration in `/etc/nixos`.  Please use the version
control system of your choice to track the changes in those files.

### `system.nix`

This file covers system-related configuration items like kernel
options, boot loader settings and basic service configurations.

The default `system.nix` contains the following options

```
  ## Activate serial console
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  ## Use the gummiboot efi boot loader.
  boot.loader.gummiboot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ## Enable EFI support for grub2 package
  boot.loader.grub.efiSupport = true;

  time.timeZone = "Europe/Zurich";

  services.openssh.enable = true;
  services.ntp.servers = [ "pool.ntp.org" ];

  environment.systemPackages = with pkgs; [
     emacs24-nox config.services.snabb.pkg exabgp
  ];

```

### `users.nix`

The `users.nix` file contains all settings related to user management.
Per default, it contains

```
 users.mutableUsers = false;
 users.extraUsers.root.hashedPassword = "$6$cSUnFL6MbD34$BaS0NLN1KCddegCaTKDMCc1D21Pdge9gFz5tr65U0KgNOgtrEoAGuVnelaPIuEb7iC0FOWE7HUG6NV2b2yN8s/";
```

The `mutableUsers` option is important to keep the configuration
strictly declarative, which means that the user databases
(`/etc/passwd`, `/etc/group` etc.) are exclusively managed by NixOS.
To maintain this paradigm, the operator *must not* use any of the
standard commands (`useradd`, `usermod` etc.) directly.  This is
enforced by excluding those commands from the system environment
(i.e. search path).

To add an account, use something like

```
  users.extraUsers.foo = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [ "ssh-dss AAAAB3NzaC1k..." ];
  };
```

See the section about the `user` configuration option in the
`configuration.nix(5)` man page for details.

### `networking`

The `networking` directory contains two files.

#### `default.nix`

This file imports `./interfaces.nix` and sets some generic (non
interface-specific) networking options.  Per default, it enables the
built-in firewall, allowing only ICMP echo requests

```
  networking.firewall = {
    enable = true;
    allowPing = true;
  };
```

#### `interfaces.nix`

This file contains all interface-specific configurations.  Per
default, it enables DHCP on all interfaces

```
  networking.useDHCP = true;
```

To create a static configuration for an interface named `eth0`, one
could use

```
  networking = {
    interfaces.eth0.ip4 = [ {
      address = "192.0.2.2";
      prefixLength = 24;
    } ];

    useDHCP = false;
    defaultGateway = "192.0.2.1";
    nameservers = [  "192.0.2.1" ];
  };
```

See the section about the `networking` configuration option in the
`configuration.nix(5)` man page for details.

### <a name="snmpd.nix">`snmpd.nix`</a>

This file contains the configuration of the SNMP daemon from the
`net-snmp` package.  The default `snmpd.nix` enables the SNMP daemon
by setting

```
services.snmpd.enable = true;
```

If this option is set to `false`, neither the SNMP daemon itself nor
any of the sub-agents will be started.

If enabled, the relevant section for the configuration is the
following:

```
    listenOn = {
      ipv4 = [ "127.0.0.1" ];
      ipv6 = [ "::1" ];
    };
    roCommunities = {
      public = {
        sources4 = [ "127.0.0.1" ];
        sources6 = [ "::1" ];
      };
    };
```

By default, the daemon only listens on `localhost` and allows read
access to the entire OID tree with community `public` from
`localhost`.  To allow remote read access, add the local addresses to
the lists in the `listenOn` section and either add remote scopes to
the `public` community or add a community of your choice, e.g.

```
    listenOn = {
      ipv4 = [ "127.0.0.1" "192.0.2.1];
      ipv6 = [ "::1" "2001:db8:0:1::1" ];
    };
    roCommunities = {
      public = {
        sources4 = [ "127.0.0.1" ];
        sources6 = [ "::1" ];
      };
      foo = {
        sources4 = [ "198.51.100.0/24" ];
        sources6 = [ "::/0" ];
      };
    };
```

### `bgp.nix`

The system includes the `exaBGP` daemon to advertise the VPN IPv6
endpoint addresses to the network.  By default, the daemon is disabled

```
  services.exabgp.enable = false;
```

To make use of this feature, enable the daemon and configure at least
one BGP peer.  The configuration includes only the setup of the
sessions.  Advertisement of reachability information is performed
automatically when the `l2vpn` service is enabled.

See the section about the `exabgp` configuration option in the
`configuration.nix(5)` man page for a description of all available
options.  The following examples treat two of the most common cases.

#### External BGP

In this configuration, the host is assigned its own AS number, usually
from the private range 64512-65534 and establishes a eBGP session with
one (or more) adjacent routers in the "core" AS:

```
  services.exabgp = {
    enable = true;
    routerID = "192.0.2.1";
    neighbors = [
      localAddress = "192.0.2.1";
      remoteAddress = "198.51.100.1";
      localAS = 64512;
      remoteAS = 64496;
      addressFamilies = [
        { afi = "ipv6"; safi = "unicast"; }
      ];
      md5 = "skjfsiowHIUHDljd";
    ];
  };
```

#### Internal BGP

In this configuration, the host is part of the core AS.  We assume
that the core AS uses route-reflectors in its iBGP mesh.  The host
establishes iBGP sessions to each route-reflector, e.g.

```
  services.exabgp =  let
    localAddress = "192.0.2.1";
    config = {
      inherit localAddress;
      localAS = 64496;
      remoteAS = 64496;
      addressFamilies = [
        { afi = "ipv6"; safi = "unicast"; }
      ];
      md5 = "skjfsiowHIUHDljd";
    };
    mkNeighbors = neighbors:
      map (n: { remoteAddress = "${n}"; } // config) neighbors;
  in {
    enable = true;
    routerID = localAddress;
    neighbors = mkNeighbors [
      "198.51.100.1"
      "198.51.100.2"
      "198.51.100.3"
    ];
  };
```

### `l2vpn.nix`

This file contains the configuration of the actual L2VPN service.  The
full set of available options of the `services.snabb` NixOS module is
part of the man page for `configuration.nix(5)`.  An excerpt
containing only the Snabb-specific options can be found in the section
[Snabb NixOS Options](#nixos-options).

The structure of the configuration is very similar to that of the the
[`l2vpn` program](https://github.com/snabbco/snabb/blob/l2vpn-v4/src/program/l2vpn/README.md#configuration).

By default, the Snabb service it is enabled but contains no interface
or VPN definitions

```
  services.snabb = {
    enable = true;
    interfaces = [];
    programs.l2vpn.instances = {};
  };
```

The configuration of interfaces differs significantly from that of the
`l2vpn` program itself and is described in the following section.

#### Device Selection and Interface configuration

The configuration of physical interfaces is logically split into two
sections.  One section assigns a globally unique name to each physical
interface and provides the specifics of its low-level configuration,
i.e. the PCI address and Snabb driver selection.

The second section provides the high-level configuration of the
interface, i.e. its properties at the link and network layers (L2/L3).

Since the low-level configuration clearly depends on features of the
hardware, it is convenient to structure it in such a manner that it
can be easily tied to specific device configurations.  The Snabb NixOS
module provides the `services.snabb.devices` option for precisely this
purpose.  The option is a two-level attribute set, where the first
level represents the name of a vendor and the second level a
particular model for this vendor.  The model contains a description of
all interfaces available on that particular device.  Consider the
following example:

```
{
  advantech = {
    FWA3230A = {
      interfaces = [
        {
          name = "GigE1/0";
          nicConfig = {
            pciAddress = "0000:0c:00.0";
            driver = {
              path = "apps.intel.intel1g";
              name = "Intel1g";
            };
          };
        }
        {
          name = "TenGigE1/1";
          nicConfig = {
            pciAddress = "0000:03:00.0";
            driver = {
              path = "apps.intel.intel_app";
              name = "Intel82599";
            };
          };
        }
      ];
    };
  };
}
```

This defines a vendor named `advantech` with a single model called
`FWA3230A`.  The device has two interfaces at PCI addresses
`0000:0c:00.0` and `0000:03:00.0`, respectively, which need to be
handled by the drivers specified by `path` and `name`.

To select this model as the active model for a ALX instance, the
following `enable` clause is added to the `services.snabb`
configuration:

```
  services.snabb = {
    enable = true;
    devices.advantech.FWA3230A.enable = true;
    interfaces = [];
    programs.l2vpn.instances = {};
  };
```

We can now proceed to add the high-level configurations of these
interfaces, for example:

```
  services.snabb = {
    enable = true;
    devices.advantech.FWA3230A.enable = true;
    interfaces = [
      {
        name = "TenGigE1/1";
        description = "Uplink";
        mtu = 9014;
        addressFamilies = {
          ipv6 = {
            address = "2001:db8:0:1::2";
            nextHop = "2001:db8:0:1::1";
          };
        };
      }
      {
        name = "GigE1/0";
        description = "Attachment Circuit VLAN trunk";
        mtu = 1518;
        trunk = {
          enable = true;
          encapsulation = "dot1q";
          vlans = [
            {
              vid = 100;
              description = "AC1";
            }
            {
              vid = 200;
              description = "AC2";
            }
          ];
        };
      }
    ];
    programs.l2vpn.instances = {};
  };
```

The `name` here must match _exactly_ that of the definitions in the
vendor/model section.

Interface `TenGigE1/1` is configured as a physical L3-port, while
`GigE1/0` is configured as a L2 trunk-port with two sub-interfaces
called `GigE1/0.100` and `GigE1/0.200` (the names are derived
automatically from the name of the underlying physical interface and
the VLAN ID, joined by a dot) on VLANs 100 and and 200, respectively.

It is convenient to store the devices list in a separate NixOS module.
By convention, these modules are located in `/etc/nixos/devices`.  The
standard `l2vpn.nix` module imports the pre-defined devices via the
instruction

```
imports = [ ./devices ];
```

which includes the module `/etc/nixos/devices/default.nix`.  This
module is just a wrapper around vendor-specific modules, which live in
subdirectories of `/etc/nixos/devices`.

A regular ALX distribution contains a set of pre-defined devices,
which can be extended by the user.  Apart from the interface
definitions, these modules may also be used to include arbitrary
system configurations specific to that device.  For example, the
`advantech` module `/etc/nixos/devices/advantech/default.nix` imports
the module `FWA3230A.nix` (located in the same directory), which looks
essentially like this:

```
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.snabb.devices.advantech;
in
{
  config = mkIf cfg.FWA3230A.enable {
    services.lcd4linux = {
      enable = true;
    };
  };
}
```

If the main configuration activates this model (via
`services.snabb.devices.advantech.FWA3230A.enable = true`), the system
service `lcd4linux` is enabled, which starts a daemon that enables the
LCD display contained in the FWA3230A.  Any model-dependent
customisations can be implemented in this manner.

#### Immediate Driver Configuration

It is possible specify the low-level configuration in the high-level
section itself by adding the same `nicConfig` option that would appear
in the vendor/model configuration.  This is called _immediate
configuration_.  The following definition is exactly equivalent to the
split configuration in the example above (note the absence of
`devices.advantech.FWA3230A.enable = true`, which defaults to `false`)

```
  services.snabb = {
    enable = true;
    interfaces = [
      {
        name = "TenGigE1/1";
        nicConfig = {
          pciAddress = "0000:03:00.0";
          driver = {
            path = "apps.intel.intel_app";
            name = "Intel82599";
          };
        };
        description = "Uplink";
        mtu = 9014;
        addressFamilies = {
          ipv6 = {
            address = "2001:db8:0:1::2";
            nextHop = "2001:db8:0:1::1";
          };
        };
      }
      {
        name = "GigE1/0";
        nicConfig = {
          pciAddress = "0000:0c:00.0";
          driver = {
            path = "apps.intel.intel1g";
            name = "Intel1g";
          };
        };
        description = "Attachment Circuit VLAN trunk";
        mtu = 1518;
        trunk = {
          enable = true;
          encapsulation = "dot1q";
          vlans = [
            {
              vid = 100;
              description = "AC1";
            }
            {
              vid = 200;
              description = "AC2";
            }
          ];
        };
      }
    ];
    programs.l2vpn.instances = {};
  };
```

In this case, no reference to the vendor/module configuration will be
made.

This method is particularly useful to define software interfaces.  For
example, the following creates a Linux `tap` device (actually a `tun`
device that provides the "wire" side of a `tuntap` device):

```
services.snabb = {
  enable = true;
  interfaces = [
    rec {
      name = "Tap1";
      nicConfig = {
        path = "apps.tap.tap";
        name = "Tap";
        literalConfig = ''${name}'';
      };
    }
  ];
}
```

For this to make sense, one needs to create the other side of the `tuntap` device, e.g.
```
# ip tuntap add Tap1 mode tap
# ip link set up dev Tap1
# ip link set address 01:02:03:04:05:06 dev Tap1
# ip addr add 192.168.1.11/24 dev Tap1
```

#### SNMP

For SNMP to be available in general, the SNMP daemon must be enabled
as described in the section about the [`snmpd.nix`](#snmpd.nix)
configuration file.

If the daemon is enabled, the `l2vpn` program unconditionally provides
the [SNMP MIBs for the
pseudowires](https://github.com/snabbco/snabb/blob/l2vpn/src/program/l2vpn/README.md#snmp)
by starting the corresponding SNMP sub-agent as a `systemd` service
called `pseudowire-snmp-subagent.service`.

Support for interface-related MIBs must be enabled separately by setting

```
services.snabb.snmp.enable = true;
```

This will start an SNMP sub-agent which will provide the data for the
`ifTable` and `ifXTable` SNMP tables through a `systemd` service
called `interface-snmp-subagent.service`.

The `l2vpn` program interacts with the sub-agent through a set of
shared memory segments, which is located by default in the directory
`/var/lib/snabb/shmem`.  This location can be changed through the
option `services.snabb.shmemDir`, e.g.

```
services.snabb.shmemDir = "/tmp";
```

#### VPN Instance Configuration

The VPN instances are configured in the attribute set
`services.snabb.programs.l2vpn.instances`.  The structure is basically
the same as the [literal configuration in
Lua](https://github.com/snabbco/snabb/blob/l2vpn/src/program/l2vpn/README.md#vpls-instance-configuration).

The translation of the [point-to-point
example](https://github.com/snabbco/snabb/blob/l2vpn/src/program/l2vpn/README.md#point-to-point-vpn)
into the configuration of the `l2vpn.nix` module would look as follows

Endpoint A:

```
services.snabb = {
  enable = true;
  snmp.enable = true;
  devices.advantech.FWA3320A.enable = true;
  interfaces = [
    {
      name = "TenGigE0/1";
      description = "uplink";
      mtu = 9206;
      addressFamilies = {
        ipv6 = {
          address = "2001:db8:0:C101:0:0:0:2";
          nextHop = "2001:db8:0:C101:0:0:0:1";
        };
      };
    }
    {
      name = "TenGigE0/0";
      description = "AC";
      mtu = 1514;
    }
  ];

  programs.l2vpn.instances = {
    vpn1 = {
      enable = true;
      uplink = "TenGigE0/1";
      vpls = {
        myvpn = {
          description = "Endpoint A of a point-to-point L2 VPN";
          mtu = 1514;
          vcID = 1;
          address = "2001:db8:0:1:0:0:0:1";
          attachmentCircuits = {
            ac_A = "TenGigE0/0";
          };
          defaultTunnel = {
            type = "l2tpv3";
            config.l2tpv3 = { 
              localCookie = "\\x00\\x11\\x22\\x33\\x44\\x55\\x66\\x77";
              remoteCookie = "\\x77\\x66\\x55\\x44\\x33\\x33\\x11\\x00";
            };
          };
          defaultControlChannel = {
            heartbeat = 2;
            deadFactor = 4;
          };
          pseudowires = {
            pw_B = {
              address = "2001:db8:0:1:0:0:0:2";
            };
          };
        };
      };
    };
  };
};

```

Endpoint B:

```
services.snabb = {
  enable = true;
  snmp.enable = true;
  interfaces = [
    {
      name = "TenGigE0/1";
      description = "uplink";
      mtu = 9206;
      addressFamilies = {
        ipv6 = {
          address = "2001:db8:0:C102:0:0:0:2";
          nextHop = "2001:db8:0:C102:0:0:0:1";
        };
      };
    }
    {
      name = "TenGigE0/0";
      description = "AC";
      mtu = 1514;
    }
  ];

  programs.l2vpn.instances = {
    vpn1 = {
      enable = true;
      uplink = "TenGigE0/1";
      vpls = {
        myvpn = {
          description = "Endpoint B of a point-to-point L2 VPN";
          mtu = 1514;
          vcID = 1;
          address = "2001:db8:0:1:0:0:0:2";
          attachmentCircuits = {
            ac_A = "TenGigE0/0";
          };
          defaultTunnel = {
            type = "l2tpv3";
            config.l2tpv3 = { 
              localCookie = "\\x77\\x66\\x55\\x44\\x33\\x33\\x11\\x00";
              remoteCookie = "\\x00\\x11\\x22\\x33\\x44\\x55\\x66\\x77";
            };
          };
          defaultControlChannel = {
            heartbeat = 2;
            deadFactor = 4;
          };
          pseudowires = {
            pw_A = {
              address = "2001:db8:0:1:0:0:0:1";
            };
          };
        };
      };
    };
  };
};

```

## <a name="nixos-options">Snabb NixOS Options</a>
```
CONFIGURATION.NIX(5)         NixOS Reference Pages        CONFIGURATION.NIX(5)



NAME
       configuration.nix - NixOS system configuration specification

DESCRIPTION
       The file /etc/nixos/configuration.nix contains the declarative
       specification of your NixOS system configuration. The command
       nixos-rebuild takes this file and realises the system configuration
       specified therein.

OPTIONS
       You can use the following options in configuration.nix.

       services.snabb.devices
           List of supported devices by vendor and model. The model
           descriptions contain a list of physical interfaces which defines
           their names and driver configurations. Exactly one vendor/model can
           be designated to be the active device by setting its enable option
           to true. The high-level interface configurations in
           services.snabb.interfaces refer to these definitions by name.

           Type: attribute set of attribute set of submoduless

           Default:{ }

           Example:

               {
                 advantech = {
                   FWA3230A = {
                     interfaces = {
                       name = "GigE1/0";
                       nicConfig = {
                         pciAddress = "0000:0c:00.0";
                         driver = {
                           path = "apps.inten.intel1g";
                           name = "Intel1g";
                         };
                       };
                     };
                   };
                 };
               }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.devices.<name>.<name>.enable
           Whether to enable the vendor/model-specific configuration. Only one
           vendor/model can be enabled.

           Type: boolean

           Default:false

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.devices.<name>.<name>.interfaces
           List of per-model interface definitions.

           Type: list of submodules

           Default:[ ]

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.devices.<name>.<name>.interfaces.*.name
           The name of the interface. All references to this interface must
           use this name.

           Type: string

           Default:null

           Example:"TenGigE0/0"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.devices.<name>.<name>.interfaces.*.nicConfig
           The low-level configuration of the interface.

           Type: null or submodule

           Default:null

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.devices.<name>.<name>.interfaces.*.nicConfig.driver.literalConfig
           A literal Lua expression which will be passed to the constructor of
           the driver module. If specified, it replaces the default
           configuration which consists of the PCI address and MTU.

           Type: null or string

           Default:null

           Example:

               { pciaddr = "0000:01:00.0" }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.devices.<name>.<name>.interfaces.*.nicConfig.driver.name
           The name of the driver within the module referenced by path.

           Type: string

           Example:"Intel82599"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.devices.<name>.<name>.interfaces.*.nicConfig.driver.path
           The path of the Lua module in which the driver resides.

           Type: string

           Example:"apps.intel.intel_app"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.devices.<name>.<name>.interfaces.*.nicConfig.pciAddress
           The PCI address of the interface in standard "geographical
           notation" (<domain>:<bus>:<device>.<function>). This option is
           ignored if literlConfig is specified.

           Type: null or string

           Default:null

           Example:"0000:01:00.0"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.enable
           Whether to enable the Snabb service. When disabled, no instance
           will be started. When enabled, individual instances can be enabled
           or disabled independently.

           Type: boolean

           Default:false

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.instances
           Private option used by Snabb program sub-modules. Do not use in
           regular NixOS configurations.

           Type: list of attribute sets

           Default:[ ]

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces
           A list of interface configurations. If the nicConfig option is not
           present, then name must refer to an interface defined in the
           vendor/model description referred to by the services.snabb.device
           option. That definition must have a nicConfig attribute which will
           be used for the low-level configuration of the interface.

           Type: list of submodules

           Default:[ ]

           Example:

               [ {
                   name = "TenGigE0/0";
                   description = "VPNTP uplink";
                   mtu = 1514;
                   addressFamilies = {
                     ipv6 = {
                       address = "2001:db8:0:1:0:0:0:2";
                       nextHop = "2001:db8:0:1:0:0:0:1";
                     };
                   };
                   trunk = { enable = false; };
                 }
                 {
                   name = "TenGigE0/1";
                   description = "VPNTP uplink";
                   mtu = 9018;
                   trunk = {
                     enable = true;
                     encapsulation = "dot1q";
                     vlans = [
                       {
                         description = "AC";
                         vid = 100;
                       }
                       {
                         description = "VPNTP uplink#2";
                         vid = 200;
                         addressFamilies = {
                           ipv6 = {
                             address = "2001:db8:0:2:0:0:0:2";
                             nextHop = "2001:db8:0:2:0:0:0:1";
                           };
                         };
                       }
                     ];
                   };
                 }
                 { name = "Tap1";
                   description = "AC";
                   nicConfig = {
                     driver = {
                       path = "apps.tap.tap";
                       name = "Tap";
                       literalConfig = "Tap1";
                     };
                   };
                   mtu = 1514;
                 }
               ]

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.addressFamilies
           An optional set of address family configurations. Providing this
           option designates the physical interface as a L3 interface.
           Currently, only ipv6 is supported. This option is only allowed if
           trunking is disabled.

           Type: null or submodule

           Default:null

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.addressFamilies.ipv6
           An optional IPv6 configuration of the subinterface.

           Type: null or submodule

           Default:null

           Example:

               {
                 ipv6 = {
                   address = "2001:db8:0:1::2";
                   nextHop = "2001:db8:0:1::1";
                 };
               }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.addressFamilies.ipv6.address
           The IPv6 address assigned to the interface. A netmask of /64 is
           implied.

           Type: string

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.addressFamilies.ipv6.enableInboundND
           If the nextHopMacAddress option is set, this option determines
           whether neighbor solicitations for the local interface address are
           processed. If disabled, the adjacent host must use a static
           neighbor cache entry for the local IPv6 address in order to be able
           to deliver packets destined for the interface. If nextHopMacAddress
           is not set, this option is ignored.

           Type: boolean

           Default:true

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.addressFamilies.ipv6.nextHop
           The IPv6 address used as next-hop for all packets sent outbound on
           the interface. It must be part of the same subnet as the local
           address.

           Type: string

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.addressFamilies.ipv6.nextHopMacAddress
           The optional MAC address that belongs to the nextHop address.
           Setting this option disables dynamic neighbor discovery for the
           nextHop address on the interface.

           Type: null or string

           Default:null

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.description
           An optional verbose description of the interface. This string is
           exposed in the ifAlias object if SNMP is enabled for the interface.

           Type: null or string

           Example:

               10GE-SFP+ link to foo

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.mtu
           The MTU of the interface in bytes, including the full Ethernet
           header. In particular, if the interface is configured as VLAN
           trunk, the 4 bytes attributed to the VLAN tag must be included in
           the MTU.

           Type: integer

           Default:1514

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.name
           The name of the interface. This can be an arbitrary string which
           uniquely identifies the interface in the list
           services.snabb.interfaces. If VLAN-based sub-interfaces are used,
           the name must not contain any dots. Otherwise, the operator is free
           to chose any suitable naming convention. It is important to note
           that it is this name which is used to identify the interface within
           network management protocols such as SNMP (where the name is stored
           in the ifDescr and ifName objects) and not the PCI address. A
           persistent mapping of interface names to integers is created from
           the lists services.snabb.interfaces and
           services.snabb.subInterfaces by assigning numbers to subsequent
           interfaces in the list, starting with 1. In the context of SNMP,
           these numbers are used as the ifIndex to identify each interface in
           the relevant MIBs.

           Type: string

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.nicConfig
           The low-level configuration of the interface.

           Type: null or submodule

           Default:null

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.nicConfig.driver.literalConfig
           A literal Lua expression which will be passed to the constructor of
           the driver module. If specified, it replaces the default
           configuration which consists of the PCI address and MTU.

           Type: null or string

           Default:null

           Example:

               { pciaddr = "0000:01:00.0" }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.nicConfig.driver.name
           The name of the driver within the module referenced by path.

           Type: string

           Example:"Intel82599"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.nicConfig.driver.path
           The path of the Lua module in which the driver resides.

           Type: string

           Example:"apps.intel.intel_app"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.nicConfig.pciAddress
           The PCI address of the interface in standard "geographical
           notation" (<domain>:<bus>:<device>.<function>). This option is
           ignored if literlConfig is specified.

           Type: null or string

           Default:null

           Example:"0000:01:00.0"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.enable
           Whether to configure the interface as a VLAN trunk.

           Type: boolean

           Default:false

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.encapsulation
           The encapsulation used on the VLAN trunk (ignored if trunking is
           disabled), either "dot1q" or "dot1ad" or an explicit ethertype. The
           ethertypes for "dot1a" and "dot1ad" are set to 0x8100 and 0x88a8,
           respectivley. An explicit ethertype must be specified as a string
           to allow hexadecimal values. The value itself will be evaluated
           when the configuration is processed by Lua.

           Type: one of "dot1q", "dot1ad" or string

           Default:"dot1q"

           Example:"0x9100"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans
           A list of vlan defintions.

           Type: list of submodules

           Default:[ ]

           Example:

               [ { description = "VLAN100";
                   vid = 100; }
                 { description = "VLAN200";
                   vid = 200;
                   addressFamilies = {
                     ipv6 = {
                       address = "2001:db8:0:1::2";
                       nextHop = "2001:db8:0:1::1";
                     };
                   }; }
                ]

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans.*.addressFamilies
           An optional set of address family configurations. Providing this
           option designates the sub-interface as a L3 interface. Currently,
           only ipv6 is supported.

           Type: null or submodule

           Default:null

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans.*.addressFamilies.ipv6
           An optional IPv6 configuration of the subinterface.

           Type: null or submodule

           Default:null

           Example:

               {
                 ipv6 = {
                   address = "2001:db8:0:1::2";
                   nextHop = "2001:db8:0:1::1";
                 };
               }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans.*.addressFamilies.ipv6.address
           The IPv6 address assigned to the interface. A netmask of /64 is
           implied.

           Type: string

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans.*.addressFamilies.ipv6.enableInboundND
           If the nextHopMacAddress option is set, this option determines
           whether neighbor solicitations for the local interface address are
           processed. If disabled, the adjacent host must use a static
           neighbor cache entry for the local IPv6 address in order to be able
           to deliver packets destined for the interface. If nextHopMacAddress
           is not set, this option is ignored.

           Type: boolean

           Default:true

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans.*.addressFamilies.ipv6.nextHop
           The IPv6 address used as next-hop for all packets sent outbound on
           the interface. It must be part of the same subnet as the local
           address.

           Type: string

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans.*.addressFamilies.ipv6.nextHopMacAddress
           The optional MAC address that belongs to the nextHop address.
           Setting this option disables dynamic neighbor discovery for the
           nextHop address on the interface.

           Type: null or string

           Default:null

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans.*.description
           A verbose description of the interface.

           Type: string

           Default:""

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.interfaces.*.trunk.vlans.*.vid
           The VLAN ID assigned to the subinterface in the range 0-4094. The
           ID 0 designates the subinterfaces to which all untagged packets are
           assigned.

           Type: integer

           Default:0

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.pkg
           The package that provides the Snabb switch software, depending on
           which feature set is desired.

           Type: package

           Default:(build of snabb-2016.08)

           Example:

               pkgs.snabbL2VPN

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.programOptions
           Default command-line options passed to all service instances.

           Type: string

           Default:""

           Example:

               -jv=dump

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.programs.l2vpn.instances
           Set of definitions of L2VPN termination points (VPNTP).

           Type: attribute set of submodules

           Default:{ }

           Example:

               TBD

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.enable
           Whether to start this VPNTP instance.

           Type: boolean

           Default:false

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.programOptions
           Command-line options to pass to this service instance. If not
           specified, the default options are applied.

           Type: null or string

           Default:null

           Example:

               -jv=dump

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls
           A set of VPLS instance definitions.

           Type: attribute set of submodules

           Default:{ }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.address
           The IPv6 address which uniquely identifies the VPLS instance.

           Type: string

           Default:null

           Example:"2001:DB8:0:1::1"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.attachmentCircuits
           An attribute set that defines all attachment circuits which will be
           part of the VPLS instance. Each AC must refer to the name of a L2
           interface defined in the interfaces option of the VPNTP instance.

           Type: attribute set of strings

           Default:{ }

           Example:

               { ac1 = "TenGigE0/0";
                 ac2 = "TenGigE0/1.100"; }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.bridge
           The configuration of the bridge module for a multi-point VPN.

           Type: submodule

           Default:{ type = "learning"; }

           Example:

               {
                 type = "learning";
                 config.learning = {
                   macTable = {
                     verbose = false;
                     timeout = 30;
                   };
                 };
               }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.bridge.config.learning.macTable
           Configuration of the MAC address table assoiciated with the
           learning bridge.

           Type: submodule

           Default:{ }

           Example:

               { verbose = true; timeout = 60; }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.bridge.config.learning.macTable.timeout
           The interval in seconds, after which a dynamically learned source
           MAC address is deleted from the MAC address table if no activity
           has been observed during that interval.

           Type: integer

           Default:30

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.bridge.config.learning.macTable.verbose
           If enabled, report information about table usage at every timeout
           interval.

           Type: boolean

           Default:false

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.bridge.type
           bridge type

           Type: one of "flooding", "learning"

           Default:"learning"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultControlChannel
           The default control-channel configuration for pseudowires. This can
           be overriden in the per-pseudowire configurations.

           Type: submodule

           Default:{ deadFactor = 3; heartbeat = 10; }

           Example:

               { heartbeat = 10;
                 deadFactor = 3; }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultControlChannel.deadFactor
           The number of successive heartbeat intervals after which the peer
           is declared to be dead (unrechable) unless at least one heartbeat
           message has been received.

           Type: integer

           Default:3

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultControlChannel.enable
           Wether to enable the control channel.

           Type: boolean

           Default:true

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultControlChannel.heartbeat
           The interval in seconds at which heartbeat messages are sent to the
           peer. The value 0 disables the control channel.

           Type: integer

           Default:10

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultTunnel
           The default tunnel configuration for pseudowires. This can be
           overriden in the per-pseudowire configurations.

           Type: submodule

           Default:{ type = "l2tpv3"; }

           Example:

               { type = "l2tpv3";
                 config.l2tpv3 = {
                   localCookie = "\x00\x11\x22\x33\x44\x55\x66\x77";
                   remoteCookie = "\x00\x11\x22\x33\x44\x55\x66\x77";
                 };
               }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultTunnel.config.gre.checksum
           If true, checksumming is enabled for the GRE tunnel.

           Type: boolean

           Default:false

           Example:

               true

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultTunnel.config.gre.key
           An optional 32-bit value which is included in the "key" field of
           the GRE header. If set to null, the key field is not included in
           the header. If used, both sides of the tunnel must use the same
           value.

           Type: null or string

           Default:null

           Example:

               0x12345678

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultTunnel.config.l2tpv3.localCookie
           A 64-bit number which is compared to the cookie field of the L2TPv3
           header of incoming packets. It must match the value configured as
           remote cookie at the remote end of the tunnel. The number must be
           represented as a string using the convention for encoding arbitrary
           byte values in Lua.

           Type: string

           Default:''\x00\x00\x00\x00\x00\x00\x00\x00''

           Example:

               "\\x00\\x11\\x22\\x33\\x44\\x55\\x66\\x77"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultTunnel.config.l2tpv3.remoteCookie
           A 64-bit number which is placed in the cookie field of the L2TPv3
           header of packets sent to the remote end of the tunnel. It must
           match the value configured as the local cookie at the remote end of
           the tunnel. The number must be represented as a string using the
           convention for encoding arbitrary byte values in Lua.

           Type: string

           Default:''\x00\x00\x00\x00\x00\x00\x00\x00''

           Example:

               "\\x00\\x11\\x22\\x33\\x44\\x55\\x66\\x77"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.defaultTunnel.type
           Tunnel type

           Type: one of "l2tpv3", "gre"

           Default:"l2tpv3"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.description
           Description of this VPLS instance.

           Type: string

           Default:""

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.mtu
           The MTU in bytes of the VPLS instance, including the entire
           Ethernet header (in particular, any VLAN tags used by the client,
           i.e. "non service-delimiting tags"). The MTU must be consistent
           across the entire VPLS. If the control-channel is enabled, this
           value is announced to the remote pseudowire endpoints and a
           mismatch of local and remote MTUs will result in the pseudowire
           being disabled.

           Type: integer

           Default:null

           Example:1514

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires
           Definition of the pseudowires attached to the VPLS instance. The
           pseudowires must be configured as a full mesh between all endpoints
           which are part of the same VPLS.

           Type: attribute set of submodules

           Default:{ }

           Example:

               { pw1 = {
                   address = "2001:db8:0:1::1";
                   tunnel = {
                     type = "gre";
                   };
                   controlChannel = { enable = false; };
                 };
                 pw2 = {
                   address = "2001:db8:0:2::1";
                   tunnel = {
                     type = "l2tpv3";
                   };
                 };
               }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.address
           The IPv6 address of the remote end of the tunnel.

           Type: string

           Default:null

           Example:"2001:DB8:0:1::1"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.controlChannel
           The configuration of the control-channel of this pseudowire. This
           overrides the default control-channel configuration for the VPLS
           instance

           Type: null or submodule

           Default:null

           Example:

               { heartbeat = 10;
                 deadFactor = 3; }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.controlChannel.deadFactor
           The number of successive heartbeat intervals after which the peer
           is declared to be dead (unrechable) unless at least one heartbeat
           message has been received.

           Type: integer

           Default:3

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.controlChannel.enable
           Wether to enable the control channel.

           Type: boolean

           Default:true

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.controlChannel.heartbeat
           The interval in seconds at which heartbeat messages are sent to the
           peer. The value 0 disables the control channel.

           Type: integer

           Default:10

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.tunnel
           The configuration of the tunnel for this pseudowire. This overrides
           the default tunnel configuration for the VPLS instance.

           Type: null or submodule

           Default:null

           Example:

               { type = "l2tpv3";
                 config.l2tpv3 = {
                   localCookie = "\x00\x11\x22\x33\x44\x55\x66\x77";
                   remoteCookie = "\x00\x11\x22\x33\x44\x55\x66\x77";
                 };
               }

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.tunnel.config.gre.checksum
           If true, checksumming is enabled for the GRE tunnel.

           Type: boolean

           Default:false

           Example:

               true

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.tunnel.config.gre.key
           An optional 32-bit value which is included in the "key" field of
           the GRE header. If set to null, the key field is not included in
           the header. If used, both sides of the tunnel must use the same
           value.

           Type: null or string

           Default:null

           Example:

               0x12345678

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.tunnel.config.l2tpv3.localCookie
           A 64-bit number which is compared to the cookie field of the L2TPv3
           header of incoming packets. It must match the value configured as
           remote cookie at the remote end of the tunnel. The number must be
           represented as a string using the convention for encoding arbitrary
           byte values in Lua.

           Type: string

           Default:''\x00\x00\x00\x00\x00\x00\x00\x00''

           Example:

               "\\x00\\x11\\x22\\x33\\x44\\x55\\x66\\x77"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.tunnel.config.l2tpv3.remoteCookie
           A 64-bit number which is placed in the cookie field of the L2TPv3
           header of packets sent to the remote end of the tunnel. It must
           match the value configured as the local cookie at the remote end of
           the tunnel. The number must be represented as a string using the
           convention for encoding arbitrary byte values in Lua.

           Type: string

           Default:''\x00\x00\x00\x00\x00\x00\x00\x00''

           Example:

               "\\x00\\x11\\x22\\x33\\x44\\x55\\x66\\x77"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.pseudowires.<name>.tunnel.type
           Tunnel type

           Type: one of "l2tpv3", "gre"

           Default:"l2tpv3"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.uplink
           The name of a L3 interface which is used to send and receive
           encapsulated packets. The named interface must exist in the
           interfaces option of the VPNTP instance.

           Type: string

           Example:"TenGigE0/0.100"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.instances.<name>.vpls.<name>.vcID
           The VC ID assigned to this VPLS instance. It is advertised through
           the control channel (and required to be identical on both sides of
           a pseudowire) but not used for multiplexing/demultiplexing of VPN
           traffic.

           Type: integer

           Default:1

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.programs.l2vpn.programOptions
           Default command-line options to pass to each service instance. If
           not specified, the global default options are applied.

           Type: null or string

           Default:null

           Example:

               -jv=dump

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb/programs/
               l2vpn>

       services.snabb.shmemDir
           Path to a directory where Snabb processes create shared memory
           segments. This is used by the legacy lib/ipc/shmem mechanism.

           Type: string

           Default:"/var/lib/snabb/shmem"

           Example:

               "/var/run/snabb"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.snmp.enable
           Whether to enable SNMP for interfaces. Currently, SNMP is enabled
           unconditionally for pseudowires.

           Type: boolean

           Default:false

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.snmp.interval
           The interval in seconds in which the SNMP objects exported via
           shared memory segments to the SNMP sub-agents are synchronized with
           the underlying data sources such as interface counters.

           Type: integer

           Default:5

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.stateDir
           Path to a directory where Snabb processes can store persistent
           state.

           Type: string

           Default:"/var/lib/snabb"

           Example:

               "/var/lib/snabb"

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

       services.snabb.subInterfaces
           A list of names of sub-interfaces for which additional ifIndex
           mappings will be created. This is a private option and is populated
           by the program modules.

           Type: unspecified

           Default:[ ]

           Declared by:
               <nixpkgs/nixos/modules/services/networking/snabb>

AUTHOR
       Eelco Dolstra
           Author

COPYRIGHT
       Copyright (C) 2007-2015 Eelco Dolstra



NixOS                             08/19/2016              CONFIGURATION.NIX(5)
```
