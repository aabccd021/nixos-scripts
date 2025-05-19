host=""
user="root"
secret_file=""
secret_name=""
secret_path=""
system=""
flags=""

while [ $# -gt 0 ]; do
  case "$1" in
  --host)
    host="$2"
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
  --secret-path)
    secret_path="$2"
    shift 2
    ;;
  --user)
    user="$2"
    shift 2
    ;;
  --system)
    system="$2"
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

if [ -z "$secret_file" ]; then
  echo "Missing --secret-file"
  exit 1
fi

if [ -z "$secret_name" ]; then
  echo "Missing --secret-name"
  exit 1
fi

if [ -z "$secret_path" ]; then
  echo "Missing --secret-path"
  exit 1
fi

if [ -z "$system" ]; then
  echo "Missing --system"
  exit 1
fi

if [ -z "$SSHPASS" ]; then
  echo "SSHPASS is not set, please set it to the password of the user"
  exit 1
fi

nix build --no-link ".#nixosConfigurations.$system.config.system.build.toplevel"

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root" || exit 1

extra_files=$(mktemp -d)
cleanup() {
  rm -rf "$extra_files"
}
trap cleanup EXIT

target_age_key_path="$extra_files/$secret_path"
install -d -m755 "$(dirname "$target_age_key_path")"

sops \
  --decrypt \
  --extract "[\"$secret_name\"]" \
  --output "$target_age_key_path" \
  "$secret_file"

eval "nix run github:nix-community/nixos-anywhere -- \
  --extra-files '$extra_files' \
  --flake '.#$system' \
  --env-password \
  --target-host '$user@$host' \
  $flags \
"
