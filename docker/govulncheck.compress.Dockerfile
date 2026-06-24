FROM govulncheck.slim

# docker-slim builds from the (non-root) full image; re-assert the unprivileged
# user and Go cache env on the final slim image so it never runs as root even if
# the slimming step drops that metadata.
ENV HOME=/home/nonroot \
    GOCACHE=/home/nonroot/.cache/go-build \
    GOMODCACHE=/home/nonroot/go/pkg/mod
USER 10001
