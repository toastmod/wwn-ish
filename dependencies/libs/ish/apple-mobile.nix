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

  buildPhase = ''
    runHook preBuild

    if [ -z "''${XCODE_APP:-}" ]; then
      XCODE_APP=$(${xcodeUtils.findXcodeScript}/bin/find-xcode || true)
      [ -n "$XCODE_APP" ] && export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
    fi

    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export CURL_CA_BUNDLE=$SSL_CERT_FILE

    ${iosToolchain.mkIOSBuildEnv {
      inherit simulator;
      minVersion = mobile.minVersion;
    }}

    meson setup build-arm64-release -Dguest_arch=arm64 --buildtype=releasemeson 
    ninja -C build-arm64-release

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    cp build-arm64-release/libish.a $out/lib/
    cat > $out/include/wawona-ish.h <<'EOF'
#ifndef WAWONA_ISH_H
#define WAWONA_ISH_H
int ish_main(int argc, char **argv);
#endif
EOF
  '';

  meta = with lib; {
    description = "iSH-arm64 in-process archive for Apple mobile";
    homepage = "https://github.com/toastmod/ish-arm64";
    license = licenses.asl20;
    platforms = platforms.darwin;
  };
}