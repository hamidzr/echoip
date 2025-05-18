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

echo "downloading GeoLite2-Country database..."
set +x
curl -sSL -u "$MAXMIND_ACC_ID:$MAXMIND_LICENSE_KEY" \
  "https://download.maxmind.com/geoip/databases/GeoLite2-Country/download?suffix=tar.gz" \
  -o GeoLite2-Country.tar.gz
set -x

echo "extracting mmdb..."
tar -xzvf GeoLite2-Country.tar.gz
mmdb_path=$(find . -name '*.mmdb' | head -n 1)
if [ -z "$mmdb_path" ]; then
  echo "could not find .mmdb file after extraction"
  exit 1
fi

out_dir=/opt/echoip
mkdir -p $out_dir
cp "$mmdb_path" $out_dir/GeoLite2-Country.mmdb
rm -rf GeoLite2-Country.tar.gz ./*GeoLite2*/ # clean up extracted dirs
echo "GeoLite2-Country.mmdb ready"
