# Build
FROM golang:1.15-buster AS build
WORKDIR /go/src/github.com/mpolden/echoip

ARG MAXMIND_ACC_ID
ARG MAXMIND_LICENSE_KEY

COPY . .

# download and extract GeoLite2 Country database
RUN apt-get update && apt-get install -y curl tar
RUN curl -J -L -u $MAXMIND_ACC_ID:$MAXMIND_LICENSE_KEY "https://download.maxmind.com/geoip/databases/GeoLite2-Country/download?suffix=tar.gz" -o GeoLite2-Country.tar.gz
RUN tar -xzvf GeoLite2-Country.tar.gz
RUN find . -name '*.mmdb' -exec cp '{}' ./GeoLite2-Country.mmdb ';'

# Must build without cgo because libc is unavailable in runtime image
ENV GO111MODULE=on CGO_ENABLED=0
RUN make

# Run
FROM scratch
EXPOSE 8080

COPY --from=build /go/bin/echoip /opt/echoip/
COPY --from=build /go/src/github.com/mpolden/echoip/GeoLite2-Country.mmdb /opt/echoip/
COPY html /opt/echoip/html

WORKDIR /opt/echoip
ENTRYPOINT ["/opt/echoip/echoip", "-f", "/opt/echoip/GeoLite2-Country.mmdb", "-t", "html"]
