# Build
FROM golang:1.15-buster AS build
WORKDIR /go/src/github.com/mpolden/echoip

COPY . .

# copy prepped GeoLite2 Country database
COPY GeoLite2-Country.mmdb ./

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
