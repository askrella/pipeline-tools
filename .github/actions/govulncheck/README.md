# govulncheck Action

Runs [`govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) against your Go code using a
prebuilt, size optimized image, so you get vulnerability scanning in CI without installing the tool on
every run.

## Prerequisites

The action pulls its image from the GitHub Container Registry, so the image needs to exist first. It is
built and published by the [`ci-build.yml`](../../workflows/ci-build.yml) reusable workflow (driven by
the `trigger-push-main` and `trigger-release` entrypoints) at:

```
ghcr.io/<owner>/pipeline-tools/govulncheck:latest-slim
```

The job that uses the action needs `packages: read` permission to pull it. Composite actions cannot
declare their own permissions, so you set them on the calling job (shown below).

## Usage

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read
    steps:
      - uses: actions/checkout@v4

      - name: Run govulncheck
        uses: ./.github/actions/govulncheck
        with:
          directory: .          # optional, defaults to "."
          fail-on-vuln: true     # optional, defaults to true
```

## Inputs

| Input | Description | Required | Default |
| --- | --- | --- | --- |
| `directory` | Directory to scan. Must exist and contain a `go.mod`. | No | `.` |
| `fail-on-vuln` | Fail the step when vulnerabilities are found. Set to `false` to warn only. | No | `true` |
| `parameters` | Extra flags passed straight to `govulncheck`, for example `-json -v`. | No | `""` |
| `version` | Image tag to run. | No | `latest-slim` |
| `image` | Image reference without tag. Override to pull from a fork or internal registry. | No | `ghcr.io/askrella/pipeline-tools/govulncheck` |
| `offline` | Run air-gapped against the bundled database (see below). | No | `false` |

## Outputs

| Output | Description |
| --- | --- |
| `scan-output` | The full scan output. |
| `error-output` | Anything the scan wrote to standard error. |
| `has-vulnerabilities` | `true` or `false`, whether any vulnerabilities were found. |
| `duration_ms` | How long the scan took, in milliseconds. |

## Scanning more than one directory

Add a step per directory. A library package can warn instead of failing while your main package fails
the build:

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read
    steps:
      - uses: actions/checkout@v4

      - name: Scan main package
        uses: ./.github/actions/govulncheck
        with:
          directory: ./cmd/main

      - name: Scan libraries
        uses: ./.github/actions/govulncheck
        with:
          directory: ./pkg
          fail-on-vuln: false
```

## Offline / air-gapped

Set `offline: true` for sandboxes with no outbound network. The action switches to the
`latest-slim-offline` image (which bundles the vulnerability database), runs `govulncheck` with
`-db file:///opt/vulndb`, and sets `GOPROXY=off`:

```yaml
      - name: Run govulncheck (offline)
        uses: ./.github/actions/govulncheck
        with:
          directory: .
          offline: true
```

- `latest-slim-offline` is a rolling tag that is overwritten when the database changes. It **cannot be
  pinned**.
- Your own modules must already be available offline (vendored or pre-cached). `GOPROXY=off` makes a
  missing module fail fast rather than reach the network.

## Notes

- The default `latest-slim` tag is a multi-arch image, so it runs on both amd64 and arm64 runners.
- `govulncheck` checks your dependencies against the Go vulnerability database, which is fetched fresh
  at scan time (or bundled in, with `offline: true`), so results stay current even though the image is
  pinned.
- Want to be sure an image matches a plain `go install govulncheck` run? Use the drift check via the
  [`govulncheck-eval`](../govulncheck-eval) action.
