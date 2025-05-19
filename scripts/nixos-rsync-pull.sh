host=""
host_public_key=""
secret_file=""
secret_name=""
src=""
dst=""
flags=""

while [ $# -gt 0 ]; do
  case "$1" in
  --host)
    host="$2"
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
  --from)
    src="$2"
    shift 2
    ;;
  --to)
    dst="$2"
    shift 2
    ;;
  --)
    shift
    flags="$*"
    break
    ;;
  *)
    break
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

if [ -z "$src" ]; then
  echo "Missing --from"
  exit 1
fi

if [ -z "$dst" ]; then
  echo "Missing --to"
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

eval "rsync \
  -e 'ssh -i $tmpdir/private_key -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$tmpdir/known_hosts' \
  $flags \
  root@$host:$src \
  $dst \
"
