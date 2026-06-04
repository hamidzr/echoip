#!/bin/sh

refresh_days=${MAXMIND_REFRESH_DAYS:-7}
should_prep=false

for db in \
  /opt/echoip/GeoLite2-Country.mmdb \
  /opt/echoip/GeoLite2-City.mmdb \
  /opt/echoip/GeoLite2-ASN.mmdb; do
  if [ ! -f "$db" ] || find "$db" -mtime +"$refresh_days" -print | grep -q .; then
    should_prep=true
    break
  fi
done

# prep maxmind dbs if any are missing or stale
if [ "$should_prep" = true ]; then
  sh /opt/echoip/prep-maxmind.sh
fi

# start echoip with correct flags for proxy support
exec /opt/echoip/echoip \
  -H x-forwarded-for \
  -f /opt/echoip/GeoLite2-Country.mmdb \
  -c /opt/echoip/GeoLite2-City.mmdb \
  -a /opt/echoip/GeoLite2-ASN.mmdb \
  -t html
