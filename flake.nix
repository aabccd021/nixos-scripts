{

  nixConfig.allow-import-from-derivation = false;

  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nixos-anywhere.url = "github:nix-community/nixos-anywhere";

  outputs =
    { self, ... }@inputs:
    let

      lib = inputs.nixpkgs.lib;

      collectInputs =
        is:
        pkgs.linkFarm "inputs" (
          builtins.mapAttrs (
            name: i:
            pkgs.linkFarm name {
              self = i.outPath;
              deps = collectInputs (lib.attrByPath [ "inputs" ] { } i);
            }
          ) is
        );

      allInputs = collectInputs inputs;

      overlay = (_: prev: import ./default.nix { pkgs = prev; });

      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shellcheck.options = [
          "-s"
          "sh"
        ];
        settings.global.excludes = [ "LICENSE" ];
      };

      formatter = treefmtEval.config.build.wrapper;

      scripts = import ./default.nix { pkgs = pkgs; };

      devShells.default = pkgs.mkShellNoCC {
        buildInputs = [ pkgs.nixd ];
      };

      packages =
        scripts
        // devShells
        // {
          formatting = treefmtEval.config.build.check self;
          formatter = formatter;
          allInputs = collectInputs inputs;
        };

    in
    {

      overlays.default = overlay;
      formatter.x86_64-linux = formatter;
      devShells.x86_64-linux = devShells;
      checks.x86_64-linux = packages;

      packages.x86_64-linux = packages // rec {
        gcroot = pkgs.linkFarm "gcroot" packages;
        default = gcroot;
      };

    };
}
