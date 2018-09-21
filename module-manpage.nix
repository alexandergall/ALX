## Create manpage for the options of the snabb module
## nix-build module-manpage.nix -A snabb && man result/share/man/man5/configuration.nix.5
##
let
  pkgs = (import ./nixpkgs {}).pkgs;
  eval = (import ./nixpkgs/nixos/lib/eval-config.nix {
    inherit pkgs;
    modules = [];
  });
  config = eval.config;
  manpage = (import ./nixpkgs/nixos/doc/manual rec {
    inherit pkgs config;
    version = config.system.nixos.release;
    revision = "release-${version}";
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
