# Build
FROM golang:1.15-buster AS build
WORKDIR /go/src/github.com/mpolden/echoip

COPY . .

# Must build without cgo because libc is unavailable in runtime image
ENV GO111MODULE=on CGO_ENABLED=0
RUN make

# Run
FROM alpine:3.20
EXPOSE 8080

RUN apk add --no-cache curl tar

COPY --from=build /go/bin/echoip /opt/echoip/
COPY html /opt/echoip/html
COPY scripts/prep-maxmind.sh /opt/echoip/prep-maxmind.sh

WORKDIR /opt/echoip
ENTRYPOINT ["/bin/sh", "-c", "if [ ! -f /opt/echoip/GeoLite2-Country.mmdb ]; then sh /opt/echoip/prep-maxmind.sh; fi && /opt/echoip/echoip -f /opt/echoip/GeoLite2-Country.mmdb -t html"]
