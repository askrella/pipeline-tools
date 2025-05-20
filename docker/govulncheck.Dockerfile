FROM golang:1.24.2-alpine AS builder

RUN apk add --no-cache git ca-certificates

# Build tools
RUN go install -ldflags="-s -w" golang.org/x/vuln/cmd/govulncheck@latest \
    && go install -ldflags="-s -w" golang.org/x/vuln/cmd/govulncheck/integration/stackrox-scanner@latest

# Final image
FROM alpine:latest

RUN apk add --no-cache ca-certificates

# Copy required Go runtime files (no compiler)
COPY --from=builder /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:$PATH"

# Copy govulncheck + stackrox
COPY --from=builder /go/bin/govulncheck /usr/local/bin/govulncheck

RUN find /usr/local/go -type d -name testdata -prune -exec rm -rf {} +

WORKDIR /app
ENTRYPOINT ["govulncheck"]
