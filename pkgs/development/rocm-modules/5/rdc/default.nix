{
  lib,
  stdenv,
  fetchFromGitHub,
  rocmUpdateScript,
  cmake,
  rocm-smi,
  rocm-runtime,
  libcap,
  grpc,
  protobuf,
  openssl,
  doxygen,
  graphviz,
  texliveSmall,
  gtest,
  buildDocs ? true,
  buildTests ? false,
}:

let
  latex = lib.optionalAttrs buildDocs (
    texliveSmall.withPackages (
      ps: with ps; [
        changepage
        latexmk
        varwidth
        multirow
        hanging
        adjustbox
        collectbox
        stackengine
        enumitem
        alphalph
        wasysym
        sectsty
        tocloft
        newunicodechar
        etoc
        helvetic
        wasy
        courier
      ]
    )
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "rdc";
  version = "5.7.1";

  outputs =
    [
      "out"
    ]
    ++ lib.optionals buildDocs [
      "doc"
    ]
    ++ lib.optionals buildTests [
      "test"
    ];

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "rdc";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-xZD/WI/LfNtKK9j6ZjuU0OTTFZz3G4atyD5mVcSsQ8A=";
  };

  nativeBuildInputs =
    [
      cmake
      protobuf
    ]
    ++ lib.optionals buildDocs [
      doxygen
      graphviz
      latex
    ];

  buildInputs =
    [
      rocm-smi
      rocm-runtime
      libcap
      grpc
      openssl
    ]
    ++ lib.optionals buildTests [
      gtest
    ];

  cmakeFlags =
    [
      "-DCMAKE_VERBOSE_MAKEFILE=OFF"
      "-DRDC_INSTALL_PREFIX=${placeholder "out"}"
      "-DBUILD_ROCRTEST=ON"
      "-DRSMI_INC_DIR=${rocm-smi}/include"
      "-DRSMI_LIB_DIR=${rocm-smi}/lib"
      "-DGRPC_ROOT=${grpc}"
      # Manually define CMAKE_INSTALL_<DIR>
      # See: https://github.com/NixOS/nixpkgs/pull/197838
      "-DCMAKE_INSTALL_BINDIR=bin"
      "-DCMAKE_INSTALL_LIBDIR=lib"
      "-DCMAKE_INSTALL_INCLUDEDIR=include"
      "-DCMAKE_INSTALL_LIBEXECDIR=libexec"
      "-DCMAKE_INSTALL_DOCDIR=doc"
    ]
    ++ lib.optionals buildTests [
      "-DBUILD_TESTS=ON"
    ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "file(STRINGS /etc/os-release LINUX_DISTRO LIMIT_COUNT 1 REGEX \"NAME=\")" "set(LINUX_DISTRO \"NixOS\")"
  '';

  postInstall =
    ''
      find $out/bin -executable -type f -exec \
        patchelf {} --shrink-rpath --allowed-rpath-prefixes "$NIX_STORE" \;
    ''
    + lib.optionalString buildTests ''
      mkdir -p $test
      mv $out/bin/rdctst_tests $test/bin
    '';

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  meta = with lib; {
    description = "Simplifies administration and addresses infrastructure challenges in cluster and datacenter environments";
    homepage = "https://github.com/ROCm/rdc";
    license = with licenses; [ mit ];
    teams = [ teams.rocm ];
    platforms = platforms.linux;
    # broken = versions.minor finalAttrs.version != versions.minor rocm-smi.version || versionAtLeast finalAttrs.version "6.0.0";
    broken = true; # Too many errors, unsure how to fix
  };
})
