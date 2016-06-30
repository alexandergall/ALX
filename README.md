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
the endpoints of any pseudowire must be large enough to accomodate the
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
     `nix-channel --remove nixos` has effctively removed the nixpkgs sources
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

### `snmpd.nix`

This file contains the configuration of the SNMP daemon from the
`net-snmp` package.  The relevant section is this:

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

This file contains the configuration of the actual L2VPN service.  By
default, it is enabled but contains no VPNs

```
  services.snabb = {
    enable = true;
    interfaces = [];
    programs.l2vpn.instances = {};
  };
```

The first step is to add the list of interfaces that are available for
uplinks or attachment circuits to the `interfaces` list by their PCI
addresses, e.g.

```
  interfaces = [ "0000:04:00.0" "0000:04:00.1" ];
```

The VPNs themselves are configured in the attribute set
`programs.l2vpn.instances`.  The structure is almost the same as the
[literal configuration in
Lua](https://github.com/snabbco/snabb/blob/l2vpn/src/program/l2vpn/README.md#configuration).

The full documentation of the NixOS options can be found in the
description of the `snabb` option in the `configuration.nix(5)`
man page.

The translation of the [point-to-point
example](https://github.com/snabbco/snabb/blob/l2vpn/src/program/l2vpn/README.md#point-to-point-vpn)
into the configuration of the `l2vpn.nix` module would look as follows

Endpoint A:

```
  programs.l2vpn.instances = {
    vpn1 = {
      enable = true;
      uplink = {
        interface = {
          driver = {
            path = "apps.intel.intel_app";
            name = "Intel82599";
          };
          config = {
            pciAddress = "0000:04:00.1"
            mtu = 9206;
            snmpEnable = true;
          };
        };
        ipv6Address = "2001:db8:0:C101:0:0:0:2";
        macAddress = "90:e2:ba:62:86:e5";
        nextHop = "2001:db8:0:C101:0:0:0:1";
      };
      vpls = {
        myvpn = {
          description = "Endpoint A of a point-to-point L2 VPN";
          mtu = 1514;
          vcID = 1;
          address = "2001:db8:0:1:0:0:0:1";
          attachmentCircuits = {
            ac_A = {
              interface = {
                driver = {
                  path = "apps.intel.intel_app";
                  name = "Intel82599";
                };
                config = {
                  pciAddress = "0000:04:00.0"
                  snmpEnable = true;
                };
              };
            };
            pseudowires = {
              pw_B = {
                address = "2001:db8:0:1:0:0:0:2";
                tunnel = {
                  type = "l2tpv3";
                  localCookie = "\\x00\\x11\\x22\\x33\\x44\\x55\\x66\\x77";
                  remoteCookie = "\\x77\\x66\\x55\\x44\\x33\\x33\\x11\\x00";
                };
                controlChannel = {
                  heartbeat = 2;
                  deadFactor = 4;
                };
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
  programs.l2vpn.instances = {
    vpn1 = {
      enable = true;
      uplink = {
        interface = {
          driver = {
            path = "apps.intel.intel_app";
            name = "Intel82599";
          };
          config = {
            pciAddress = "0000:04:00.1"
            mtu = 9206;
            snmpEnable = true;
          };
        };
        ipv6Address = "2001:db8:0:C102:0:0:0:2";
        macAddress = "90:e2:ba:62:86:e6";
        nextHop = "2001:db8:0:C102:0:0:0:1";
      };
      vpls = {
        myvpn = {
          description = "Endpoint B of a point-to-point L2 VPN";
          mtu = 1514;
          vcID = 1;
          address = "2001:db8:0:1:0:0:0:2";
          attachmentCircuits = {
            ac_B = {
              interface = {
                driver = {
                  path = "apps.intel.intel_app";
                  name = "Intel82599";
                };
                config = {
                  pciAddress = "0000:04:00.0"
                  snmpEnable = true;
                };
              };
            };
            pseudowires = {
              pw_A = {
                address = "2001:db8:0:1:0:0:0:1";
                tunnel = {
                  type = "l2tpv3";
                  localCookie = "\\x77\\x66\\x55\\x44\\x33\\x33\\x11\\x00";
                  remoteCookie = "\\x00\\x11\\x22\\x33\\x44\\x55\\x66\\x77";
                };
                controlChannel = {
                  heartbeat = 2;
                  deadFactor = 4;
                };
              };
            };
          };
        };
      };
    };
  };

```
