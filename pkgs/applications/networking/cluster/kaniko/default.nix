{ stdenv
, lib
, fetchFromGitHub
, buildGoModule
, installShellFiles
, testers
, kaniko
}:

buildGoModule rec {
  pname = "kaniko";
  version = "1.9.1";

  src = fetchFromGitHub {
    owner = "GoogleContainerTools";
    repo = "kaniko";
    rev = "v${version}";
    hash = "sha256-sPICsDgkijQ7PyeTWQgT553toc4/rWPPo7SY3ptX82U=";
  };

  vendorHash = null;

  ldflags = [
    "-s" "-w"
    "-X github.com/GoogleContainerTools/kaniko/pkg/version.version=${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  doCheck = false; # requires docker, container-diff (unpackaged yet)

  postInstall = lib.optionalString (stdenv.hostPlatform == stdenv.buildPlatform) ''
    for shell in bash fish zsh; do
      $out/bin/executor completion $shell > executor.$shell
      installShellCompletion executor.$shell
    done
  '';

  passthru.tests.version = testers.testVersion {
    package = kaniko;
    version = version;
    command = "${kaniko}/bin/executor version";
  };

  meta = {
    description = "A tool to build container images from a Dockerfile, inside a container or Kubernetes cluster";
    homepage = "https://github.com/GoogleContainerTools/kaniko";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.superherointj ];
    mainProgram = "executor";
  };
}
