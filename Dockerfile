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
COPY docker-entrypoint.sh /opt/echoip/docker-entrypoint.sh
RUN chmod +x /opt/echoip/docker-entrypoint.sh

WORKDIR /opt/echoip
ENTRYPOINT ["/opt/echoip/docker-entrypoint.sh"]
