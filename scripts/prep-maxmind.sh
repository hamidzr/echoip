#!/usr/bin/env sh

set -ex

# load env vars from .env if present
if [ -f .env ]; then
  . .env
fi

if [ -z "$MAXMIND_ACC_ID" ] || [ -z "$MAXMIND_LICENSE_KEY" ]; then
  echo "MAXMIND_ACC_ID and MAXMIND_LICENSE_KEY must be set in the environment or .env"
  exit 1
fi

download_db() {
  db_name="$1"
  out_path="$2"
  archive="${db_name}.tar.gz"

  echo "downloading ${db_name} database..."
  set +x
  curl -sSL -u "$MAXMIND_ACC_ID:$MAXMIND_LICENSE_KEY" \
    "https://download.maxmind.com/geoip/databases/${db_name}/download?suffix=tar.gz" \
    -o "$archive"
  set -x

  echo "extracting ${db_name} mmdb..."
  tar -xzvf "$archive"
  mmdb_path=$(find . -name "${db_name}.mmdb" | head -n 1)
  if [ -z "$mmdb_path" ]; then
    echo "could not find ${db_name}.mmdb after extraction"
    exit 1
  fi

  cp "$mmdb_path" "$out_path"
  rm -rf "$archive" ./*GeoLite2*/ # clean up extracted dirs
  echo "${db_name}.mmdb ready"
}

out_dir=/opt/echoip
mkdir -p "$out_dir"

download_db GeoLite2-Country "$out_dir/GeoLite2-Country.mmdb"
download_db GeoLite2-City "$out_dir/GeoLite2-City.mmdb"
download_db GeoLite2-ASN "$out_dir/GeoLite2-ASN.mmdb"
