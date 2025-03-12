{ pkgs }:
let
  scriptDefs = {
    nixos-rebuild-local = [ pkgs.sops ];
    nixos-rebuild-remote = [ pkgs.sops pkgs.openssh ];
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

