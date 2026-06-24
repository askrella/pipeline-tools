# GOLANG_VERSION is REQUIRED and must be sourced from the root go.mod `go`
# directive by the caller (CI workflow / check.sh). That directive is the single
# source of truth, so a Dependabot bump there propagates here automatically.
# No default on purpose: an empty value fails the build fast rather than
# silently pinning a stale version.
ARG GOLANG_VERSION
FROM golang:${GOLANG_VERSION}-alpine AS builder

RUN apk add --no-cache git ca-certificates

# Build tools. Pin the version for reproducible images (the vulnerability
# database is still fetched fresh at scan time, so pinning the binary does not
# stale the results). govulncheck and stackrox-scanner share the x/vuln module
# version.
ARG GOVULNCHECK_VERSION=v1.4.0
RUN go install -ldflags="-s -w" golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION} \
    && go install -ldflags="-s -w" golang.org/x/vuln/cmd/govulncheck/integration/stackrox-scanner@${GOVULNCHECK_VERSION}

# Final image. Pinned to a digest (not the floating `latest`) for reproducible
# builds; Dependabot's docker updater keeps the tag + digest fresh.
FROM alpine:3.22@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

RUN apk add --no-cache ca-certificates git && update-ca-certificates
# Copy required Go runtime files (no compiler)
COPY --from=builder /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:$PATH"

# Copy govulncheck + stackrox-scanner
COPY --from=builder /go/bin/govulncheck /usr/local/bin/govulncheck
COPY --from=builder /go/bin/stackrox-scanner /usr/local/bin/stackrox-scanner

RUN find /usr/local/go -type d -name testdata -prune -exec rm -rf {} +

# Run as an unprivileged user. govulncheck only reads the workspace mounted at
# /app and writes its build cache under $HOME, so a dedicated non-root user that
# owns its cache dir is enough. docker-slim probes as this same user (its
# default) and keeps file perms, so the slim image stays non-root and writable.
ENV HOME=/home/nonroot \
    GOCACHE=/home/nonroot/.cache/go-build \
    GOMODCACHE=/home/nonroot/go/pkg/mod
RUN adduser -D -u 10001 nonroot \
 && mkdir -p /home/nonroot/.cache/go-build /home/nonroot/go/pkg/mod \
 && chown -R 10001:10001 /home/nonroot

WORKDIR /app
USER 10001
ENTRYPOINT ["govulncheck"]
