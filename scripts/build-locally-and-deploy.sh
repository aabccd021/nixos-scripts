repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root" || exit 1

tmpdir=$(mktemp -d)
chmod 700 "$tmpdir"
trap 'rm -rf $tmpdir' EXIT

sops \
  --decrypt \
  --extract '["ssh-client-key"]' \
  --output "$tmpdir/private_key" \
  ./secrets.yaml

chmod 400 "$tmpdir/private_key"

ip="10.244.32.193"

echo "$ip ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuR7GY+Vul3Yez3lKfM4Wm8wmKX8L63vsFo1EAFDraF" >"$tmpdir/known_hosts"

NIX_SSHOPTS="
  -i $tmpdir/private_key 
  -o StrictHostKeyChecking=yes
  -o UserKnownHostsFile=$tmpdir/known_hosts
" \
  exec nixos-rebuild switch \
  --flake .#default \
  --target-host "root@$ip"
