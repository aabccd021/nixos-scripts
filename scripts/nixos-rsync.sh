ip=""
host_public_key=""
secret_file=""
secret_name=""

while true; do
  case "$1" in
  --ip)
    ip="$2"
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
  *)
    break
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

echo "$ip $host_public_key" >"$tmpdir/known_hosts"

exec rsync \
  -e "ssh -i $tmpdir/private_key -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$tmpdir/known_hosts" \
  "$@"
