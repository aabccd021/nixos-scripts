host=""
name=""
host_public_key=""
secret_file=""
secret_name=""
user="root"

while [ $# -gt 0 ]; do
  case "$1" in
  --host)
    host="$2"
    shift 2
    ;;
  --name)
    name="$2"
    shift 2
    ;;
  --host-public-key)
    host_public_key="$2"
    shift 2
    ;;
  --secret-file)
    secret_file="$2"
    shift 2
    ;;
  --secret-name)
    secret_name="$2"
    shift 2
    ;;
  --user)
    user="$2"
    shift 2
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

if [ -z "$host" ]; then
  echo "Missing --host"
  exit 1
fi

if [ -z "$host_public_key" ]; then
  echo "Missing --host-public-key"
  exit 1
fi

if [ -z "$secret_file" ]; then
  echo "Missing --secret-file"
  exit 1
fi

if [ -z "$secret_name" ]; then
  echo "Missing --secret-name"
  exit 1
fi

trap 'cd $(pwd)' EXIT
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root" || exit 1

tmpdir=$(mktemp -d)

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

sops \
  --decrypt \
  --extract "[\"$secret_name\"]" \
  --output "$tmpdir/private_key" \
  "$secret_file"

chmod 600 "$tmpdir/private_key"

echo "$host $host_public_key" >"$tmpdir/known_hosts"

set -x
rsync \
  -e "ssh -i $tmpdir/private_key -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$tmpdir/known_hosts" \
  --delete \
  --archive \
  --info=progress2 \
  --human-readable \
  --no-inc-recursive \
  --exclude='/.git' \
  --filter="dir-merge,- .gitignore" \
  ./ \
  "$user@$host:/tmp/nixos-config"

exec ssh \
  -t \
  -i "$tmpdir/private_key" \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile="$tmpdir/known_hosts" \
  "$user@$host" \
  "cd /tmp/nixos-config &&
   nix --extra-experimental-features 'nix-command flakes' run nixpkgs#git -- config --global --add safe.directory \$PWD &&
   nixos-rebuild switch --flake /tmp/nixos-config#$name --accept-flake-config
  "
