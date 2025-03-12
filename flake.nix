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
      };

      scriptDefs = {
        # build-locally-and-deploy = [ pkgs.sops ];
        # send-code-and-rebuild = [ pkgs.sops pkgs.openssh ];
        nixos-ssh = [ pkgs.sops pkgs.openssh ];
      };

      scripts = builtins.mapAttrs
        (name: runtimeInputs: pkgs.writeShellApplication {
          name = name;
          runtimeInputs = runtimeInputs;
          text = builtins.readFile "${./scripts}/${name}.sh";
        })
        scriptDefs;

      packages = scripts // {
        formatting = treefmtEval.config.build.check self;
      };

      apps = builtins.mapAttrs
        (name: script: {
          type = "app";
          program = pkgs.lib.getExe script;
        })
        scripts;


    in
    {

      overlays.x86_64-linux = overlay;

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      packages.x86_64-linux = packages;

      apps.x86_64-linux = apps;

      checks.x86_64-linux = packages;
    };
}
