#!/bin/sh

geoip_source=${GEOIP_SOURCE:-dbip}
geoip_dir=${GEOIP_DIR:-/opt/echoip}
refresh_days=${GEOIP_REFRESH_DAYS:-${MAXMIND_REFRESH_DAYS:-7}}
should_prep=false

case "$geoip_source" in
  dbip)
    country_db="$geoip_dir/dbip-city-lite.mmdb"
    city_db="$geoip_dir/dbip-city-lite.mmdb"
    asn_db="$geoip_dir/dbip-asn-lite.mmdb"
    ;;
  maxmind)
    country_db="$geoip_dir/GeoLite2-Country.mmdb"
    city_db="$geoip_dir/GeoLite2-City.mmdb"
    asn_db="$geoip_dir/GeoLite2-ASN.mmdb"
    ;;
  *)
    echo "unsupported GEOIP_SOURCE: $geoip_source" >&2
    exit 1
    ;;
esac

for db in "$country_db" "$city_db" "$asn_db"; do
  if [ ! -f "$db" ] || find "$db" -mtime +"$refresh_days" -print | grep -q .; then
    should_prep=true
    break
  fi
done

# prep geoip dbs if any are missing or stale
if [ "$should_prep" = true ]; then
  GEOIP_SOURCE="$geoip_source" GEOIP_DIR="$geoip_dir" sh /opt/echoip/prep-maxmind.sh
fi

# start echoip with correct flags for proxy support
exec /opt/echoip/echoip \
  -H x-forwarded-for \
  -f "$country_db" \
  -c "$city_db" \
  -a "$asn_db" \
  -t html
