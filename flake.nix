{
  description = "Some flake-based project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    steam-fetcher = {
      url = "github:aidalgol/nix-steam-fetcher?ref=overlay-pattern";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    steam-fetcher,
  }:
    with flake-utils.lib;
      eachDefaultSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [steam-fetcher.overlays.default];
        };

        linters = with pkgs; [
          alejandra
          statix
        ];
      in {
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs;
              [
                nil # Nix LS
              ]
              ++ linters;
          };
        };

        checks = builtins.mapAttrs (name: pkgs.runCommandLocal name {nativeBuildInputs = linters;}) {
          alejandra = "alejandra --check ${./.} > $out";
          statix = "statix check ${./.} > $out";
        };

        formatter = pkgs.writeShellApplication {
          name = "fmt";
          runtimeInputs = linters;
          text = ''
            alejandra --quiet .
            statix fix .
          '';
        };
      })
      // {
        nixosModules = rec {
          valheim = ./nixos-modules/valheim.nix;
          default = valheim;
        };
      }
      // {
        overlays.default = final: prev: {
          valheim-server-unwrapped = pkgs.callPackage ./pkgs/valheim-server {};
          valheim-server = pkgs.callPackage ./pkgs/valheim-server/fhsenv.nix {};
          valheim-plus = pkgs.callPackage ./pkgs/valheim-plus {};
        };
      };
}
