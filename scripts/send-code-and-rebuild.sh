repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root" || exit 1

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

sops \
  --decrypt \
  --extract '["ssh-client-key"]' \
  --output "$tmpdir/private_key" \
  ./secrets.yaml

chmod 600 "$tmpdir/private_key"

ip="10.244.32.193"

echo "$ip ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuR7GY+Vul3Yez3lKfM4Wm8wmKX8L63vsFo1EAFDraF" >"$tmpdir/known_hosts"

rsync \
  -e "ssh -i $tmpdir/private_key -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$tmpdir/known_hosts" \
  --delete \
  --archive \
  --info=progress2 \
  --human-readable \
  --no-inc-recursive \
  ./ \
  root@"$ip":/tmp/nixos-config

exec ssh \
  -t \
  -i "$tmpdir/private_key" \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile="$tmpdir/known_hosts" \
  "root@$ip" \
  "cd /tmp/nixos-config &&
   nix --extra-experimental-features 'nix-command flakes' run nixpkgs#git -- config --global --add safe.directory \$PWD &&
   nixos-rebuild switch --flake /tmp/nixos-config#default --accept-flake-config
  "
