host=""
host_public_key=""
secret_file=""
identity="$HOME/.ssh/id_ed25519"
user="root"
port="22"

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
  --identity)
    identity="$2"
    shift 2
    ;;
  --user)
    user="$2"
    shift 2
    ;;
  --port)
    port="$2"
    shift 2
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

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

age -d -i "$identity" -o "$tmpdir/private_key" "$secret_file"

chmod 400 "$tmpdir/private_key"

known_host="$host"
if [ "$port" != "22" ]; then
  known_host="[$host]:$port"
fi

echo "$known_host $host_public_key" >"$tmpdir/known_hosts"

mosh \
  --ssh="ssh
    -i $tmpdir/private_key
    -o StrictHostKeyChecking=yes
    -o UserKnownHostsFile=$tmpdir/known_hosts
    -p $port" \
  "$user@$host" "$@"
