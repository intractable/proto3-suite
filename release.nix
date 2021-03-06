# To build this repository with `nix` you run:
#
#     $ nix-build release.nix
#
# The update process for this repository is a little bit complicated due to
# unusual needs of our test suite.
#
# If you update the `.cabal` file (such as changing dependencies or adding new
# library/executable/test/benchmark sections), then update the `default.nix`
# expression by running:
#
#     $ cabal2nix . > default.nix
#
# Then modify the file to add `doCheck = false;` to disable tests.  Also, modify
# the `default-tests.nix` file so that the attribute set expected by the
# function:
#
#     attrs@
#     { mkDerivation, base, bytestring, cereal, containers, deepseq
#     , filepath, haskell-src, mtl, parsec, parsers, pipes, pretty
#     , proto3-wire, QuickCheck, safe, semigroups, stdenv, tasty
#     , tasty-hunit, tasty-quickcheck, text, transformers, turtle, vector
#     }:
#
# ... matches the attribute set expected by `default.nix`.
#
# If you want to update the `proto3-wire` dependency to the latest git revision,
# then run:
#
#     $ nix-prefetch-git https://github.com/awakenetworks/proto3-wire.git
#
# ... and modify the `rev` and `sha256` fields of the corresponding `fetchgit`
# expression below using the output of the `nix-prefetch-git` command.
#
# If you want to test a local `proto3-wire` repository, then replace the
# `fetchgit { ... }` expression with the relative path to the source repository
# such as:
#
#     let proto3-wire-src = ../proto3-wire;
#     in
#     ...
let config = {
  packageOverrides = pkgs:
  let python_protobuf3_0 = (pkgs.pythonPackages.protobufBuild pkgs.protobuf3_0).override {
      doCheck = false;
    };
  in
  { haskellPackages = pkgs.haskell.packages.ghc7103.override {
      overrides = haskellPackagesNew: haskellPackagesOld: {
        proto3-wire =
          let proto3-wire-src = pkgs.fetchgit {
            url    = "https://github.com/awakenetworks/proto3-wire.git";
            rev    = "1b88bf24aad15db1f59a00d201d609fa308157f7";
            sha256 = "02gsj0qyqqnqawm7s2h4y2510j82jv4jq2gsyadmck1ihlc9pfvl";
          };
          in
          haskellPackagesNew.callPackage proto3-wire-src { };

        proto3-suite-no-tests =
          haskellPackagesNew.callPackage ./default.nix { };

        proto3-suite =
          haskellPackagesNew.callPackage (import ./default-tests.nix {
            inherit python_protobuf3_0;
            inherit (pkgs) bash ghc protobuf3_0 python writeText;
            inherit (haskellPackagesNew) proto3-suite-no-tests;
          }) { };
      };
    };
  };

  allowUnfree = true;
};

in
{ pkgs ? import <nixpkgs> { inherit config; } }:
{ proto3-suite-no-tests = pkgs.haskellPackages.proto3-suite-no-tests;
  proto3-suite = pkgs.haskellPackages.proto3-suite;
}
