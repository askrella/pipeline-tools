#!/usr/bin/env bash

docker-slim build \
  --target govulncheck \
  --cmd govulncheck \
  --exec '
        go build main.go && \
        # Open every Go tool so Slim includes them all:
        find "$(go env GOROOT)/pkg/tool" -type f -exec head -c1 {} \; && \
        govulncheck . 2>&1 || true
    ' \
  --mount "$PWD/go.mod:/app/go.mod" \
  --mount "$PWD/go.sum:/app/go.sum" \
  --mount "$PWD/main.go:/app/main.go" \
  --http-probe=false