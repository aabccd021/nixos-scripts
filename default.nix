{ pkgs }:
let
  scriptDefs = {
    nixos-rebuild-local = [ pkgs.sops pkgs.openssh ];
    nixos-rebuild-remote = [ pkgs.sops pkgs.openssh pkgs.rsync ];
    nixos-ssh = [ pkgs.sops pkgs.openssh ];
    nixos-rsync = [ pkgs.sops pkgs.openssh pkgs.rsync ];
  };
in

builtins.mapAttrs
  (name: runtimeInputs: pkgs.writeShellApplication {
    name = name;
    runtimeInputs = runtimeInputs;
    text = builtins.readFile "${./scripts}/${name}.sh";
  })
  scriptDefs

