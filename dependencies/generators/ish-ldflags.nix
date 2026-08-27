# Link flags for in-process iSH on Apple targets.
# Pass nativeDeps with iSH from mobile-platform-deps.

{ lib, deps, forceLoad ? true }:

let
  strip = d: if d == null then "" else toString d;
  ish = deps.ish or null;
  libff = if ish != null then "${strip ish}/lib/libish.a" else "";
  fwFile = if ish != null then "${strip ish}/nix-support/ish-frameworks" else "";
  frameworks =
    if fwFile != "" && builtins.pathExists fwFile
    then lib.filter (s: s != "") (lib.splitString "\n" (builtins.readFile fwFile))
    else [ "CoreFoundation" "Foundation" ];
  frameworkFlags = lib.concatMap (f: [ "-framework" f ]) frameworks;
in
if forceLoad && ish != null && builtins.pathExists libff then
  [ "-force_load" libff ] ++ frameworkFlags
else
  [ ]