{ lib, stdenvNoCC, fetchurl }:

let
  # Upstream minio/minio archived its repo in 2025 after gutting the open
  # source Console/community edition in favor of their commercial AIStor
  # product — nixpkgs' own `minio` package is stuck on whatever predates
  # that. pgsty/minio (the Pigsty project, which depends on MinIO for its
  # Postgres backup/object-storage stack) forks and continues publishing
  # community-maintained releases from the same source, same GoReleaser
  # asset layout upstream used. Bump releaseTag/assetVersion/sha256
  # together from https://github.com/pgsty/minio/releases when updating.
  releaseTag = "RELEASE.2026-06-18T00-00-00Z";
  assetVersion = "20260618000000.0.0";
in
stdenvNoCC.mkDerivation {
  pname = "minio";
  version = assetVersion;

  src = fetchurl {
    url = "https://github.com/pgsty/minio/releases/download/${releaseTag}/minio_${assetVersion}_linux_amd64.tar.gz";
    sha256 = "0ba637b050be30d8c65142798c363cfb7392bf731d2f572aefd2e7bf1fd59a10";
  };

  # The tarball has LICENSE/README.md/minio directly at its root, no
  # wrapping directory — nix's default unpack-then-cd-into-the-one-dir
  # behavior has nothing to cd into without this.
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  # A statically-linked Go binary (confirmed via `file`/`ldd`) — no
  # autoPatchelfHook or dynamic linker fixup needed, unlike most prebuilt
  # third-party binaries packaged this way.
  installPhase = ''
    runHook preInstall
    install -Dm755 minio $out/bin/minio
    install -Dm444 LICENSE $out/share/doc/minio/LICENSE
    install -Dm444 README.md $out/share/doc/minio/README.md
    runHook postInstall
  '';

  meta = {
    description = "High-performance S3-compatible object store — community-maintained build (pgsty/minio) since upstream minio/minio archived its repo";
    homepage = "https://github.com/pgsty/minio";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "minio";
  };
}
