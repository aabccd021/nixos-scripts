{ pkgs }:
let
  scriptDefs = {
    nixos-rebuild-local = [
      pkgs.age
      pkgs.coreutils
      pkgs.nix
      pkgs.nixos-rebuild
      pkgs.openssh
    ];
    nixos-rebuild-remote = [
      pkgs.age
      pkgs.coreutils
      pkgs.git
      pkgs.nix
      pkgs.nixos-rebuild
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-ssh = [
      pkgs.age
      pkgs.coreutils
      pkgs.openssh
    ];
    nixos-mosh = [
      pkgs.age
      pkgs.coreutils
      pkgs.mosh
    ];
    nixos-rsync-push = [
      pkgs.age
      pkgs.coreutils
      pkgs.git
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-rsync-pull = [
      pkgs.age
      pkgs.coreutils
      pkgs.git
      pkgs.openssh
      pkgs.rsync
    ];
    nixos-init-server = [
      pkgs.age
      pkgs.coreutils
      pkgs.git
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
