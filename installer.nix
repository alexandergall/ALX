## Build an instance of the PXE-based fully-automated installer,
## consisting of a tarball of a root filesystem, EFI boot loader and a
## kernel.

{ system ? "x86_64-linux" }:

with import <nixpkgs> { inherit system; };
with lib;

let

  customConfig = ./installer-config.nix;
  nfsroot = (import <nixpkgs/nixos/lib/eval-config.nix> {
    inherit system;
    modules = [ installer/modules/installer-nfsroot.nix ]
     ++ (optional (pathExists customConfig) customConfig);
  }).config.system.build.nfsroot;

  jobs = rec {
    inherit (nfsroot) nfsRootTarball bootLoader kernel;
  };
in
  jobs
