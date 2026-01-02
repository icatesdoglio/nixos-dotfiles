{ inputs }:
final: prev: {
  dwm       = prev.callPackage "${inputs.suckless}/dwm" { };
  dmenu     = prev.callPackage "${inputs.suckless}/dmenu" { };
  st        = prev.callPackage "${inputs.suckless}/st" { };
  dwmblocks = prev.callPackage "${inputs.suckless}/dwmblocks" { };
}

