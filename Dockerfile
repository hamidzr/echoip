# syntax=docker/dockerfile:1

# Build
FROM golang:1.27.3-bookworm@sha256:d9b6a1beb9474adc2a1ce842573639b44b2a0dd49b6669f51d3821baf9ec37c9 AS build
WORKDIR /go/src/github.com/mpolden/echoip

# Must build without cgo because libc is unavailable in runtime image
ENV GO111MODULE=on CGO_ENABLED=0
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build make

# Run
FROM alpine:3.20@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc
EXPOSE 8080

RUN apk add --no-cache curl tar

COPY --from=build /go/bin/echoip /opt/echoip/
COPY html /opt/echoip/html
COPY scripts/prep-maxmind.sh /opt/echoip/prep-maxmind.sh
COPY docker-entrypoint.sh /opt/echoip/docker-entrypoint.sh
RUN chmod +x /opt/echoip/docker-entrypoint.sh \
    && addgroup -S echoip && adduser -S -G echoip -H -h /opt/echoip echoip \
    && chown echoip:echoip /opt/echoip  # dir only: GeoIP downloads land here, code stays root-owned

USER echoip
WORKDIR /opt/echoip

# /health is static; start-period covers the GeoIP download in the entrypoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/opt/echoip/docker-entrypoint.sh"]
