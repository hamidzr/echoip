#!/bin/sh

# prep maxmind db if not present
if [ ! -f /opt/echoip/GeoLite2-Country.mmdb ]; then
  sh /opt/echoip/prep-maxmind.sh
fi

# start echoip with correct flags for proxy support
exec /opt/echoip/echoip -H x-forwarded-for -f /opt/echoip/GeoLite2-Country.mmdb -t html 