# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  printpath = pkgs.writeShellScriptBin "printpath.sh" ''
    #!/bin/bash
    if [ -f "$1" ] ; then
      bat $*;
    else
      eza -la $*;
    fi
  '';
}
