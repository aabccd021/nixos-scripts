{ pkgs }:
let
  scriptDefs = {
    nixos-rebuild-local = [
      pkgs.sops
      pkgs.openssh
    ];
    nixos-rebuild-remote = [
      pkgs.sops
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-ssh = [
      pkgs.sops
      pkgs.openssh
    ];
    nixos-mosh = [
      pkgs.sops
      pkgs.mosh
    ];
    nixos-rsync-push = [
      pkgs.sops
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-rsync-pull = [
      pkgs.sops
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-init-server = [
      pkgs.sops
      pkgs.openssh
    ];
  };
in

builtins.mapAttrs (
  name: runtimeInputs:
  pkgs.writeShellApplication {
    name = name;
    runtimeInputs = runtimeInputs;
    text = builtins.readFile "${./scripts}/${name}.sh";
  }
) scriptDefs
