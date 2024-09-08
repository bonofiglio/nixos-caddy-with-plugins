{ lib
, buildGoModule
, fetchFromGitHub
, gnused
, installShellFiles
, nixosTests
, caddy
, testers
, stdenv
,
}:
let
  attrsToModule = map (plugin: plugin.repo);
  attrsToVersionedModule = map (
    { repo, version, ... }: lib.escapeShellArg "${repo}@${version}"
  );

in
({ caddyModules
 , vendorHash ? lib.fakeHash
 ,
 }:
buildGoModule {
  pname = "${caddy.pname}-with-plugins";
  version = caddy.version;
  src = caddy.src;
  subPackages = caddy.subPackages;
  ldflags = caddy.ldflags;
  tags = caddy.tags;
  nativeBuildInputs = caddy.nativeBuildInputs;
  postInstall = caddy.postInstall;
  meta = caddy.meta;

  modBuildPhase = ''
    for module in ${toString (attrsToModule caddyModules)}; do
      sed -i "/standard/a _ \"$module\"" ./cmd/caddy/main.go
    done
    for plugin in ${toString (attrsToVersionedModule caddyModules)}; do
      go get $plugin
    done
    go mod vendor
  '';

  modInstallPhase = ''
    mv -t vendor go.mod go.sum
    cp -r vendor "$out"
  '';

  preBuild = ''
    chmod -R u+w vendor
    [ -f vendor/go.mod ] && mv -t . vendor/go.{mod,sum}
    for module in ${toString (attrsToModule caddyModules)}; do
      sed -i "/standard/a _ \"$module\"" ./cmd/caddy/main.go
    done
  '';

  inherit vendorHash;
})
