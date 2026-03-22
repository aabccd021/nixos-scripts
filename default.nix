{ pkgs }:
let
  scriptDefs = {
    nixos-rebuild-local = [
      pkgs.age
      pkgs.openssh
    ];
    nixos-rebuild-remote = [
      pkgs.age
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-ssh = [
      pkgs.age
      pkgs.openssh
    ];
    nixos-mosh = [
      pkgs.age
      pkgs.mosh
    ];
    nixos-rsync-push = [
      pkgs.age
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-rsync-pull = [
      pkgs.age
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-init-server = [
      pkgs.age
      pkgs.openssh
    ];
  };
in

builtins.mapAttrs (
  name: runtimeInputs:
  pkgs.writeShellApplication {
    inherit name runtimeInputs;
    inheritPath = false;
    text = builtins.readFile "${./scripts}/${name}.sh";
  }
) scriptDefs
