## Build an instance of a ALX system from the ALX-branded nixpkgs tree
## in the ./nixpkgs submodule.  This includes an install image and
## configuration that can be used to install a system from scratch
## with the installer provided by installer.nix and a shell script
## that performs an upgrade of an existing ALX system to the new
## version.

{ system ? "x86_64-linux" }:

with import <nixpkgs> { inherit system; };
with lib;

let

  installImageConfig = {
    installImage = {

      ## Derive the client's configuration from the "branded" nixpkgs
      ## system in the nixpkgs submodule.
      nixpkgs = {
        path = ./nixpkgs;
        stableBranch = true;
      };
      inherit system;

      ## The contents of this directory will be copied as is to
      ## /etc/nixos on the install target.
      nixosConfigDir = ./nixos-config;

    };
  };
  customConfig = ./install-image-config.nix;

  build = (import <nixpkgs/nixos/lib/eval-config.nix> {
    inherit system;
    modules = [ installer/modules/install-image.nix
                installImageConfig
              ] ++ (optional (pathExists customConfig) customConfig);
  }).config.system.build;

  upgradeCommand = let
    channel = build.installImage.channel;
    releaseName = builtins.unsafeDiscardStringContext
      (builtins.substring 33 (-1) (baseNameOf channel));
    version = getVersion releaseName;
    upgradeScript = writeScript "upgrade"
      ''
        #!/run/current-system/sw/bin/bash
        set -e

        info() {
          echo "This archve contains ALX version ${version}"
          echo "The current system is running version $current"
          exit 0;
        }

        current=$(nixos-version | awk '{print $1}')
        while getopts if opt; do
            case $opt in
                i) info;;
                f) force=1;;
            esac
        done

        echo "Attempting to upgrade the system from version $current to ${version}"
        if [ $(nix-instantiate --eval -E "with (import <nixpkgs> {}).lib; versionOlder \"$current\" \"${version}\"") != "true" \
             -a -z "$force" ]; then
            echo "Target version is not newer than current version, use -f to " \
                 "force installation"
            exit 1
        fi

        set -- $(nix-channel --list | awk '$1 == "nixos" {print $2}')
        url=$1
        if [ ! -n "$url" ]; then
          echo "Channel \"nixos\" required for upgrade but is not configured (check \"nix-channel --list\")"
          exit 1
        fi

        set -- $(echo $url | cut -d: --output-delimiter " " -f1,2)
        method=$1
        loc=$2
        if [ "$method" != "file" ]; then
          echo "Upgrades are only supported for method \"file:\""
          exit 1;
        fi

        loc=$(echo $loc | sed -e 's!^//!!')
        dir=$(dirname $loc)
        if [ ! -d $dir ]; then
          echo "Directory $dir doesn't exist, creating"
          mkdir -p $dir
        fi
        if [ -e $loc -a ! -L $loc ]; then
          echo "$loc is expected to be a symbolic link: $(type $loc)"
          exit 1;
        fi
        if [ -d $dir/${releaseName} ]; then
          echo "$dir/${releaseName} already exists, remove manually to force upgrade"
          exit 1;
        fi
        cat ${releaseName}.tar | (cd $dir && tar xpf -)
        rm -f $loc
        ln -s ./${releaseName} $loc
        echo "Updating nixos channel"
        nix-channel --update
        echo "Reconfiguring system"
        nixos-rebuild switch

        echo "Upgrade completed, use \"nix-env -p /nix/var/nix/profiles/per-user/root/channels --rollback\" " \
             "to revert"
      '';
      selfExtractor = writeScript "self-extractor"
        ''
          #!/run/current-system/sw/bin/bash
          export TMPDIR=$(mktemp -d /tmp/selfextract.XXXXXX)
          archive=$(awk '/^___ARCHIVE_BELOW___/ {print NR + 1; exit 0; }' $0)
          tail -n+$archive $0 | tar x -C $TMPDIR
          cwd=$(pwd)
          cd $TMPDIR
          ./upgrade "$@"
          cd $cwd
          rm -rf $TMPDIR
          exit 0

          ___ARCHIVE_BELOW___
        '';

  in runCommand "${releaseName}"
    {}
    ''
      path=$out/${releaseName}
      mkdir -p $path
      (cd ${channel} && tar --transform="s/^nixos/${releaseName}/" -cJf $path/nixexprs.tar.xz nixos)
      cat ${channel}/binary-caches/nixos >$path/binary-cache-url
      (cd $out && tar cf ${releaseName}.tar ${releaseName})
      rm -rf $path
      cp -p ${upgradeScript} $out/upgrade
      (cd $out && tar cf payload.tar ${releaseName}.tar upgrade)
      cat ${selfExtractor} $out/payload.tar >$out/alx-upgrade
      chmod --reference=${selfExtractor} $out/alx-upgrade
      rm $out/${releaseName}.tar $out/upgrade $out/payload.tar
    '';

  jobs = rec {
    installImage = build.installImage.tarball;
    installConfig = build.installImage.config;
    inherit upgradeCommand;
  };
in
  jobs
