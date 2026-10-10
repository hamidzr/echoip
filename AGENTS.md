# echoip agent notes

Fork of `mpolden/echoip` (origin `hamidzr/echoip`, trunk `master`). Go IP lookup service: plain text for CLI clients, JSON, and an HTML page. Module path stays `github.com/mpolden/echoip`; keep imports as-is.

## Commands

- `make lint test`: gofmt -s check, `go vet`, `go test ./...`. Use this to verify changes.
- `make` (default `all`) also runs `go install ./...`, which writes to `$GOPATH/bin`. The Docker build relies on that.
- `make run`: local server; expects MaxMind-named DBs at `data/{asn,city,country}.mmdb`. Without DBs, run `go run ./cmd/echoip -t html` (geo routes disabled).
- `make docker-build`: builds the production image. `docker-push*`, `publish`, and `docker-login` publish externally; do not run unless asked.

## Layout

- `cmd/echoip/main.go`: flags (`-f/-c/-a` DB paths, `-H` trusted IP headers, `-t` template dir, `-C` cache size, `-r` reverse lookup, `-p` port lookup, `-P` pprof/debug routes, `-s` sponsor logo).
- `http/http.go`: handlers and route table in `Server.Handler()`. Route order matters: first match wins (JSON Accept, CLI user-agent matcher, then HTML). Geo routes register only when a DB is loaded.
- `http/router.go`: tiny custom router. `http/cache.go`: bounded response cache keyed by IP hash (`-C 0` disables).
- `iputil/geo/geo.go`: mmdb reader (`oschwald/geoip2-golang`); no tests. `useragent/`: CLI client detection.
- `html/`: Go `html/template` files loaded via `ParseGlob(<dir>/*)`; every file in the dir is parsed.

## Docker and runtime

- `Dockerfile`: Go builder runs `make` (lint + test + install), runtime is alpine with curl/tar for DB download.
- `docker-entrypoint.sh`: downloads DBs on start if missing or older than `GEOIP_REFRESH_DAYS`, then runs `echoip -H x-forwarded-for -t html`. It does not pass `-C`, `-r`, or `-p`.
- `scripts/prep-maxmind.sh`: fetches DBs. `GEOIP_SOURCE=dbip` (default, no credentials, DB-IP Lite city+ASN; city file also serves as country DB) or `maxmind` (needs `MAXMIND_ACC_ID` + `MAXMIND_LICENSE_KEY`). Vars listed in `env.example`.
- Makefile `geoip-download` uses an old `GEOIP_LICENSE_KEY` URL flow; the entrypoint/script path is the one in use.
- Never print or log MaxMind credentials (`set +x` around the curl is deliberate).
- Deployment builds the `Dockerfile` externally from `master`; no deploy config lives in this repo.

## Gotchas

- `X-Forwarded-For` handling takes the leftmost entry (trimmed). Safe only behind a proxy that overwrites the header; changes here need tests in `http/http_test.go`.
- `.github/workflows/ci.yml` is stale upstream config (Go 1.16, pushes `mpolden/echoip` to Docker Hub). Do not rely on it; verify locally.
- `go.mod` declares `go 1.13`; the builder image uses Go 1.27. Avoid needless toolchain bumps.
