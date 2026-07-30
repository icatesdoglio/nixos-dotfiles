{
  stdenv,
  lib,
  fetchurl,
  makeWrapper,
  xar,
  cpio,
  callPackage,
  nixosTests,
  buildFHSEnv,

  # Support pulseaudio by default
  pulseaudioSupport ? true,

  # Whether to support XDG portals at all
  xdgDesktopPortalSupport ? (
    plasma6XdgDesktopPortalSupport
    || lxqtXdgDesktopPortalSupport
    || gnomeXdgDesktopPortalSupport
    || hyprlandXdgDesktopPortalSupport
    || wlrXdgDesktopPortalSupport
    || xappXdgDesktopPortalSupport
  ),

  plasma6XdgDesktopPortalSupport ? false,
  lxqtXdgDesktopPortalSupport ? false,
  gnomeXdgDesktopPortalSupport ? false,
  hyprlandXdgDesktopPortalSupport ? false,
  wlrXdgDesktopPortalSupport ? false,
  xappXdgDesktopPortalSupport ? false,

  targetPkgs ? pkgs: [ ],
  targetPkgsFixed ? [ ],
}:

let
  inherit (stdenv.hostPlatform) system;

  versions.aarch64-darwin = "7.0.5.81138";
  versions.x86_64-darwin = "7.0.5.81138";
  versions.x86_64-linux = "7.1.5.4332";

  srcs = {
    aarch64-darwin = fetchurl {
      url = "https://zoom.us/client/${versions.aarch64-darwin}/zoomusInstallerFull.pkg?archType=arm64";
      name = "zoomusInstallerFull.pkg";
      hash = "sha256-uFnwBVZn5iUTIHNYG2WqiULA8siGWJaqY0BcRCoU6gg=";
    };
    x86_64-darwin = fetchurl {
      url = "https://zoom.us/client/${versions.x86_64-darwin}/zoomusInstallerFull.pkg";
      hash = "sha256-ZeTgrqkpYumSGlbv/O8/GKALns4bNaFJR3CgV4Mswb4=";
    };
    x86_64-linux = fetchurl {
      url = "https://cdn.zoom.us/prod/${versions.x86_64-linux}/zoom_x86_64.pkg.tar.xz";
      hash = "sha256-5znZNrySgRrs9I5zhqN5p5dPfXpEHXKf8o2dWeYTPso=";
    };
  };

  unpacked = stdenv.mkDerivation {
    pname = "zoom";
    version = versions.${system} or versions.x86_64-linux;

    src = srcs.${system} or srcs.x86_64-linux;

    dontUnpack = stdenv.hostPlatform.isLinux;
    unpackPhase = lib.optionalString stdenv.hostPlatform.isDarwin ''
      xar -xf $src
      zcat < zoomus.pkg/Payload | cpio -i
    '';

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
      makeWrapper
      xar
      cpio
    ];

    installPhase = ''
      runHook preInstall
    ''
    + (
      if stdenv.hostPlatform.isDarwin then
        ''
          mkdir -p $out/Applications
          cp -R zoom.us.app $out/Applications/
        ''
      else
        ''
          mkdir $out
          tar -C $out -xf $src
          mv $out/usr/* $out/
        ''
    )
    + ''
      runHook postInstall
    '';

    postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
      makeWrapper $out/Applications/zoom.us.app/Contents/MacOS/zoom.us $out/bin/zoom
    '';

    dontPatchELF = true;

    passthru.tests.nixos-module = nixosTests.zoom-us;

    meta = {
      homepage = "https://zoom.us/";
      changelog = "https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0061222";
      description = "zoom.us video conferencing application";
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      license = lib.licenses.unfree;
      platforms = builtins.attrNames srcs;
      maintainers = with lib.maintainers; [
        philiptaron
        ryan4yin
      ];
      mainProgram = "zoom";
    };
  };

  linuxGetDependencies =
    pkgs:
    [
      pkgs.alsa-lib
      pkgs.atk
      pkgs.cairo
      pkgs.cups
      pkgs.dbus
      pkgs.expat
      pkgs.fontconfig
      pkgs.freetype
      pkgs.glib
      pkgs.gtk3
      pkgs.ibus
      pkgs.libGL
      pkgs.libGLU
      pkgs.libatomic_ops
      pkgs.libdrm
      pkgs.libgbm
      pkgs.libkrb5
      pkgs.libsm
      pkgs.libxi
      pkgs.libxkbcommon
      pkgs.libxslt
      pkgs.mesa-demos
      pkgs.nspr
      pkgs.nss
      pkgs.pango
      pkgs.pciutils
      pkgs.pipewire
      pkgs.qt6.qtbase
      pkgs.qt6.qtdeclarative
      pkgs.stdenv.cc.cc
      pkgs.udev
      pkgs.wayland
      pkgs.libx11
      pkgs.libxcomposite
      pkgs.libxdamage
      pkgs.libxext
      pkgs.libxfixes
      pkgs.libxrandr
      pkgs.libxrender
      pkgs.libxtst
      pkgs.libxshmfence
      pkgs.libxcb
      pkgs.libxcb-util
      pkgs.libxcb-cursor
      pkgs.libxcb-image
      pkgs.libxcb-keysyms
      pkgs.libxcb-render-util
      pkgs.libxcb-wm
      pkgs.zlib
      pkgs.zstd
    ]
    ++ lib.optionals pulseaudioSupport [
      pkgs.libpulseaudio
      pkgs.pulseaudio
    ]
    ++ lib.optional xdgDesktopPortalSupport pkgs.xdg-desktop-portal
    ++ lib.optional plasma6XdgDesktopPortalSupport pkgs.kdePackages.xdg-desktop-portal-kde
    ++ lib.optional lxqtXdgDesktopPortalSupport pkgs.lxqt.xdg-desktop-portal-lxqt
    ++ lib.optionals gnomeXdgDesktopPortalSupport [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ]
    ++ lib.optional hyprlandXdgDesktopPortalSupport pkgs.xdg-desktop-portal-hyprland
    ++ lib.optional wlrXdgDesktopPortalSupport pkgs.xdg-desktop-portal-wlr
    ++ lib.optional xappXdgDesktopPortalSupport pkgs.xdg-desktop-portal-xapp
    ++ targetPkgs pkgs
    ++ targetPkgsFixed;

in
if !stdenv.hostPlatform.isLinux then
  unpacked
else
  buildFHSEnv {
    inherit (unpacked) pname version;

    targetPkgs = pkgs: (linuxGetDependencies pkgs) ++ [ unpacked ];
    extraPreBwrapCmds = "unset QT_PLUGIN_PATH";
    extraBwrapArgs = [ "--ro-bind ${unpacked}/opt /opt" ];
    runScript = "/opt/zoom/ZoomLauncher";

    extraInstallCommands = ''
      cp -Rt $out/ ${unpacked}/share
      substituteInPlace \
          $out/share/applications/Zoom.desktop \
          --replace-fail Exec={/usr/bin/,}zoom

      ln -s $out/bin/{zoom,zoom-us}
    '';

    passthru = unpacked.passthru // {
      inherit unpacked;
    };
    inherit (unpacked) meta;
  }
