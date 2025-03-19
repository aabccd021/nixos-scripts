{

  nixConfig.allow-import-from-derivation = false;

  inputs = {
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, treefmt-nix, }:
    let

      overlay = (_: prev: import ./default.nix { pkgs = prev; });

      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
        programs.prettier.enable = true;
        programs.stylua.enable = true;
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shellcheck.options = [ "-s" "sh" ];
        settings.global.excludes = [ "LICENSE" ];
      };

      scripts = import ./default.nix { pkgs = pkgs; };

      packages = scripts // {
        formatting = treefmtEval.config.build.check self;
      };

    in
    {

      overlays.default = overlay;

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      packages.x86_64-linux = packages;

      apps.x86_64-linux = builtins.mapAttrs
        (name: script: {
          type = "app";
          program = pkgs.lib.getExe script;
        })
        scripts;

      checks.x86_64-linux = packages;
    };
}
