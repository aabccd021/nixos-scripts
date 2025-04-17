ip=""
name=""
host_public_key=""
secret_file=""
secret_name=""
user="root"

while [ $# -gt 0 ]; do
  case "$1" in
  --ip)
    ip="$2"
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

if [ -z "$ip" ]; then
  echo "Missing --ip"
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

echo "$ip $host_public_key" >"$tmpdir/known_hosts"

NIX_SSHOPTS="-i $tmpdir/private_key -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$tmpdir/known_hosts" \
  exec nixos-rebuild switch \
  --flake ".#$name" \
  --target-host "$user@$ip"
