{
  description = "Trying to build caddy with plugins declaratively for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    caddy-cloudflare-dns = {
      url = "github:caddy-dns/cloudflare";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, flake-utils, caddy-cloudflare-dns, ... }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      caddyWithPlugins = pkgs.callPackage ./caddy-with-plugins.nix { };
    in
    rec {
      packages.default = caddyWithPlugins;
      packages.caddyWithCloudflare = caddyWithPlugins {
        caddyModules =
          [
            {
              name = "cloudflare-dns";
              repo = "github.com/caddy-dns/cloudflare";
              version = caddy-cloudflare-dns.rev;
            }
          ];
        vendorHash = import ./hash.nix;
      };

      overlays.default = final: prev: {
        caddyWithCloudflare = packages.caddyWithCloudflare;
      };
    });
}
