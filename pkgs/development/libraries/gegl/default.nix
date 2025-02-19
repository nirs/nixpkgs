{ lib
, stdenv
, fetchurl
, pkg-config
, vala
, gobject-introspection
, gtk-doc
, docbook-xsl-nons
, docbook_xml_dtd_43
, glib
, babl
, libpng
, llvmPackages
, cairo
, libjpeg
, librsvg
, lensfun
, libspiro
, maxflow
, netsurf
, pango
, poly2tri-c
, poppler
, bzip2
, json-glib
, gettext
, meson
, ninja
, libraw
, gexiv2
, libwebp
, luajit
, openexr
, OpenCL
, suitesparse
}:

stdenv.mkDerivation rec {
  pname = "gegl";
  version = "0.4.40";

  outputs = [ "out" "dev" "devdoc" ];
  outputBin = "dev";

  src = fetchurl {
    url = "https://download.gimp.org/pub/gegl/${lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "zd6A0VpJ2rmmFO+Y+ATIzm5M/hM5o8JAw08/tFQ2uF0=";
  };

  patches = [
    (fetchurl {
      name = "libraw.patch";
      url = "https://src.fedoraproject.org/cgit/rpms/gegl04.git/plain/"
          + "libraw.patch?id=5efd0c16a7b0e73abcaecc48af544ef027f4531b";
      hash = "sha256-ZgVigN1T7JmeBMwSdBsMsmXx0h7UW4Ft9HlSqeB0se8=";
    })
  ];

  nativeBuildInputs = [
    pkg-config
    gettext
    meson
    ninja
    vala
    gobject-introspection
    gtk-doc
    docbook-xsl-nons
    docbook_xml_dtd_43
  ];

  buildInputs = [
    libpng
    cairo
    libjpeg
    librsvg
    lensfun
    libspiro
    maxflow
    netsurf.libnsgif
    pango
    poly2tri-c
    poppler
    bzip2
    libraw
    libwebp
    gexiv2
    luajit
    openexr
    suitesparse
  ] ++ lib.optionals stdenv.isDarwin [
    OpenCL
  ] ++ lib.optionals stdenv.cc.isClang [
    llvmPackages.openmp
  ];

  # for gegl-4.0.pc
  propagatedBuildInputs = [
    glib
    json-glib
    babl
  ];

  mesonFlags = [
    "-Dgtk-doc=true"
    "-Dmrg=disabled" # not sure what that is
    "-Dsdl2=disabled"
    "-Dpygobject=disabled"
    "-Dlibav=disabled"
    "-Dlibv4l=disabled"
    "-Dlibv4l2=disabled"
    # Disabled due to multiple vulnerabilities, see
    # https://github.com/NixOS/nixpkgs/pull/73586
    "-Djasper=disabled"
  ];

  # TODO: Fix missing math symbols in gegl seamless clone.
  # It only appears when we use packaged poly2tri-c instead of vendored one.
  env.NIX_CFLAGS_COMPILE = "-lm";

  postPatch = ''
    chmod +x tests/opencl/opencl_test.sh
    patchShebangs tests/ff-load-save/tests_ff_load_save.sh tests/opencl/opencl_test.sh tools/xml_insert.sh
  '';

  # tests fail to connect to the com.apple.fonts daemon in sandboxed mode
  doCheck = !stdenv.isDarwin;

  meta = with lib; {
    description = "Graph-based image processing framework";
    homepage = "https://www.gegl.org";
    license = licenses.lgpl3Plus;
    maintainers = with maintainers; [ jtojnar ];
    platforms = platforms.unix;
  };
}
