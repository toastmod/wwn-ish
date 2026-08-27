# Neovim in-process static archive for Apple mobile (App Store–safe).
{
  lib,
  pkgs,
  buildPackages,
  iosToolchain,
  simulator ? false,
  xcodeUtils ? iosToolchain,
  toolchainSrc ? null,
  ...
}:

let
  mobile = (import "${toolchainSrc}/dependencies/toolchains/apple-mobile-platform.nix") {
    inherit iosToolchain simulator;
  };
  appleCmake = import "${toolchainSrc}/dependencies/toolchains/apple-cmake-toolchain.nix";
  neovimSrc = import ./common.nix { inherit pkgs; };
  version = import ./version.nix;
  helpers = import ./build-helpers.nix {
    inherit lib pkgs buildPackages neovimSrc version;
    appleMobile = true;
    inherit iosToolchain simulator xcodeUtils toolchainSrc;
  };
in
pkgs.stdenv.mkDerivation {
  pname = "ish-apple-mobile";
  inherit version;
  src = neovimSrc;

  __noChroot = true;
  dontConfigure = true;

  nativeBuildInputs = helpers.baseNative ++ [
    xcodeUtils.findXcodeScript
    pkgs.gettext
  ];

  postPatch = helpers.applyAppleMobilePatches;

  buildPhase = ''
    runHook preBuild

    if [ -z "''${XCODE_APP:-}" ]; then
      XCODE_APP=$(${xcodeUtils.findXcodeScript}/bin/find-xcode || true)
      [ -n "$XCODE_APP" ] && export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
    fi

    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export CURL_CA_BUNDLE=$SSL_CERT_FILE

    ${helpers.hostCodegenPass}

    ${iosToolchain.mkIOSBuildEnv {
      inherit simulator;
      minVersion = mobile.minVersion;
    }}

    ${appleCmake { inherit iosToolchain simulator; }}

    ${helpers.iosCrossBuildPass}

    ${helpers.collectArchive}
    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include $out/share/nvim
    cp libish.a $out/lib/
    cat > $out/include/wawona-ish.h <<'EOF'
#ifndef WAWONA_ISH_H
#define WAWONA_ISH_H
int ish_main(int argc, char **argv);
#endif
EOF
  '';

  meta = with lib; {
    description = "iSH-arm64 in-process archive for Apple mobile";
    homepage = "https://github.com/OpenMinis/ish-arm64";
    license = licenses.asl20;
    platforms = platforms.darwin;
  };
}