{ pkgs }:
let
  scriptDefs = {
    # build-locally-and-deploy = [ pkgs.sops ];
    # send-code-and-rebuild = [ pkgs.sops pkgs.openssh ];
    nixos-ssh = [ pkgs.sops pkgs.openssh ];
  };
in

builtins.mapAttrs
  (name: runtimeInputs: pkgs.writeShellApplication {
    name = name;
    runtimeInputs = runtimeInputs;
    text = builtins.readFile "${./scripts}/${name}.sh";
  })
  scriptDefs

