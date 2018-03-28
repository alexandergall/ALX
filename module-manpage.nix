## Create manpage for the options of the snabb module
## nix-build module-manpage.nix -A snabb && man result/share/man/man5/configuration.nix.5
##
let
  pkgs = (import ./nixpkgs {}).pkgs;
  eval = (import ./nixpkgs/nixos/lib/eval-config.nix {
    inherit pkgs;
    modules = [];
  });
  manpage = (import ./nixpkgs/nixos/doc/manual {
    inherit pkgs;
    version = eval.config.system.nixosVersion;
    revision = eval.config.system.nixosRevision;
    options = eval.options.services.snabb;
  }).manpages;
  manpageASCII =
    pkgs.runCommand "manpage-ascii"
    {}
    ''
      mkdir $out
      ${pkgs.man}/bin/man ${manpage}/share/man/man5/configuration.nix.5 \
        | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" >$out/configuration.nix.5
    '';
in
  {
    snabb = manpage;
    snabbASCII = manpageASCII;
}
