# Pipeline Tools

[![CI](https://github.com/askrella/pipeline-tools/actions/workflows/trigger-push-main.yml/badge.svg)](https://github.com/askrella/pipeline-tools/actions/workflows/trigger-push-main.yml)
[![Version](https://img.shields.io/github/v/release/askrella/pipeline-tools?label=version&sort=semver)](https://github.com/askrella/pipeline-tools/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Third party licenses](https://img.shields.io/badge/third--party-licenses-informational.svg)](THIRD_PARTY_LICENSES.md)

[![full image](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/askrella/pipeline-tools/badges/full.json)](https://github.com/askrella/pipeline-tools/pkgs/container/pipeline-tools%2Fgovulncheck)
[![slim image](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/askrella/pipeline-tools/badges/slim.json)](https://github.com/askrella/pipeline-tools/pkgs/container/pipeline-tools%2Fgovulncheck)
[![offline image](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/askrella/pipeline-tools/badges/offline.json)](https://github.com/askrella/pipeline-tools/pkgs/container/pipeline-tools%2Fgovulncheck)

A collection of security and quality tooling we rely on across our own and our customers' Go and
Terraform projects, packaged so you can drop it straight into a CI pipeline.

The idea is simple. Instead of every project installing the same scanners from scratch on every run,
we ship them as ready to use container images and reusable GitHub Actions, then verify they behave
the way we expect before anyone depends on them.

## Status

This repository is being built up tool by tool. Right now `govulncheck` is fully shipped: image,
action, and a drift check that proves the image matches the upstream tool. The tools below are on the
roadmap and are not published yet.

| Tool | What it does | Status |
| --- | --- | --- |
| [`govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) | Scans Go code and dependencies against the Go vulnerability database | Available |
| [`golangci-lint`](https://golangci-lint.run/) | Runs many Go linters in parallel with caching | Planned |
| [`gosec`](https://github.com/securego/gosec) | Finds security issues in Go source (hardcoded secrets, SQL injection, weak crypto) | Planned |
| [`tfsec`](https://github.com/aquasecurity/tfsec) | Security scanner for Terraform, with SARIF output for GitHub Security | Planned |
| [`terrascan`](https://github.com/tenable/terrascan) | Policy based scanner for Terraform, CloudFormation, Kubernetes and Helm | Planned |
| [`checkov`](https://www.checkov.io/) | Misconfiguration and license scanning across many IaC frameworks | Planned |

## Quick start

### Use the govulncheck image

The image is published to the GitHub Container Registry. Point it at any directory that contains a
`go.mod`:

```bash
docker run --rm -v "$PWD":/app -w /app \
  ghcr.io/askrella/pipeline-tools/govulncheck:latest-slim -scan=symbol ./...
```

### Image variants

There are three variants of the image, all multi-arch (amd64 and arm64). They run the same
`govulncheck`, so they find the same vulnerabilities. The difference is size and whether the
vulnerability database is fetched or bundled.

**Full** (`latest`, or a release tag to pin) carries the complete Go toolchain. It is the largest but
the most forgiving: if you scan an unusual project layout or hit a edge case in module loading, this is
the one most likely to just work. Reach for it when you are debugging a scan or when image size does
not matter.

**Slim** (`latest-slim`) is the full image run through docker-slim to strip everything govulncheck does
not touch at runtime. It is the default for the action and the right choice for almost every CI
pipeline: much smaller to pull, same results. If a future scan ever fails on slim but passes on full,
that is a bug worth reporting, and the [drift check](#verifying-a-replacement-before-you-trust-it)
exists precisely to catch it.

**Offline** (`latest-slim-offline`) is the slim image with the vulnerability database baked in, so
`govulncheck` never reaches `vuln.go.dev`. Use it only in air-gapped sandboxes with no outbound
network. Because a frozen database goes stale, this tag is **mutable**: we overwrite it whenever the
database changes. It **cannot be pinned**, by design. See [offline use](#offline--air-gapped-use).

| Variant | Tag | Pin with | Best for |
| --- | --- | --- | --- |
| Full | `latest` | a release tag (e.g. `v1.2.0`) or `sha-<short>` | Debugging, unusual projects, size is not a concern |
| Slim | `latest-slim` | `<release-tag>-slim` or `sha-<short>-slim` | Everyday CI (the default) |
| Offline | `latest-slim-offline` | not pinnable | Air-gapped sandboxes only |

> `latest` and `latest-slim` track the most recent release. Each release also publishes immutable
> `<release-tag>` and `<release-tag>-slim` tags (named after the GitHub release), which are what you pin
> to. Pushes to `main` additionally publish rolling `nightly` and immutable `sha-<short>` tags if you
> want to track the bleeding edge.

### Use the GitHub Action

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read
    steps:
      - uses: actions/checkout@v4
      - name: Run govulncheck
        uses: askrella/pipeline-tools/.github/actions/govulncheck@main
        with:
          directory: .
          fail-on-vuln: true
```

See the [action documentation](.github/actions/govulncheck/README.md) for every input and output.

### Offline / air-gapped use

For sandboxes with no outbound network, the `latest-slim-offline` image bundles the Go vulnerability
database, so `govulncheck` never has to reach `vuln.go.dev`. Pass `offline: true` to the action and it
switches to that image, points the scanner at the bundled database, and sets `GOPROXY=off`:

```yaml
      - name: Run govulncheck (offline)
        uses: askrella/pipeline-tools/.github/actions/govulncheck@main
        with:
          directory: .
          offline: true
```

Two things to know:

- **`latest-slim-offline` cannot be pinned.** It is a rolling tag that we overwrite whenever the
  database changes (checked daily). Pinning it would pin you to a stale database, which defeats the
  point. Use it only where you accept a mutable tag.
- **Your modules must already be available offline.** A bundled database does not help with your own
  dependencies. Vendor them (`go mod vendor`) or pre-populate the module cache before scanning. With
  `GOPROXY=off` a missing module fails fast instead of hanging.

The database is the only thing the offline image freezes, and it is roughly 2.3 MB added as a single
layer on top of the slim image, so it costs almost nothing extra to store.

## Verifying a replacement before you trust it

Swapping an existing `go install govulncheck` step for a prebuilt image only saves time if the image
finds the same vulnerabilities. Not fewer, and definitely not silently nothing. To make that
guarantee checkable, the [`govulncheck-eval`](.github/actions/govulncheck-eval) action runs up to
three variants side by side against the same target and compares what each one reports:

- `native`, the canonical `go install golang.org/x/vuln/cmd/govulncheck` path you already run
- `full`, the multi-arch image
- `slim`, the size optimized image

Each variant can be turned on or off on its own, and you decide whether a mismatch should fail the run
or just be reported.

Drop it into an existing job as a composite action — for example to confirm a specific image variant
does not break your pipeline before you adopt it:

```yaml
      - name: Verify the slim image before adopting it
        uses: askrella/pipeline-tools/.github/actions/govulncheck-eval@main
        with:
          enable-full: false      # compare native vs slim only
          slim-tag: latest-slim
          fail-on-drift: true
```

The comparison is based on the set of vulnerability IDs (OSV IDs) each variant reports, so differences
in log formatting never cause false alarms. A variant that produces no valid output is treated as a
failure too, which is exactly the silent break you want to catch. The summary lists every variant's
tool version, exit code, whether it ran, how many findings it had, and a diff against the reference.
The same action powers the air-gapped smoke test for the offline image.

We run the drift check against our own vulnerable scenario after every main push and release, so a
regression in our images is caught before it ships.

## SBOMs

Every published image carries a Software Bill of Materials (SPDX JSON, generated with
[Syft](https://github.com/anchore/syft)) attached as a signed attestation. Syft runs locally during the
build with its update check disabled, so nothing about the image contents is uploaded anywhere, and for
a private repository the attestation is stored within GitHub rather than a public transparency log.

Verify and read it with the GitHub CLI:

```bash
# verify the attestation is present and signed by this repo
gh attestation verify oci://ghcr.io/askrella/pipeline-tools/govulncheck:latest --owner askrella

# pull the SBOM document itself
gh attestation download oci://ghcr.io/askrella/pipeline-tools/govulncheck:latest --owner askrella
```

The offline image additionally **bundles** the SBOM at `/usr/share/sbom/`, so air-gapped consumers that
cannot reach the registry attestation still have a machine-readable bill of materials on disk.

## How it is built

Each tool moves through three stages:

1. **Container.** We build a shippable image so nobody has to install the tool by hand. The Go version
   comes straight from the root [`go.mod`](go.mod), which keeps a single source of truth and lets
   Dependabot roll everything forward with a one line change.
2. **Action.** We wrap the image in a reusable action and verify it against the scenarios in
   [`scenarios/`](scenarios), including a deliberately vulnerable module so we know detection actually
   fires.
3. **Workflow.** Once the baseline holds, we bundle the actions into reusable workflows that run in
   parallel.

The `scenarios/` directory holds fixture modules, pinned and left alone by Dependabot so they stay
reproducible:

- `scenarios/vulnerable` is a minimal module pinned to a known-vulnerable `golang.org/x/text`. The CI
  drift check and the action test assert that every image still flags its advisories
  (`GO-2021-0113`, `GO-2022-1059`), which is what guards against a silently broken scan.
- `scenarios/webserver` is a larger, realistic Gin application used for manual and exploratory scans
  against a fuller dependency graph. It is not wired into CI yet.

### Pipeline layout

The CI follows a split model: thin entrypoints that react to events, and reusable units that hold the
actual logic, so nothing is duplicated across pipelines.

| Entrypoint | Trigger | What it does |
| --- | --- | --- |
| [`trigger-pr.yml`](.github/workflows/trigger-pr.yml) | pull request | Lint, secret scan, test, build (no push). Auto-merges passing Dependabot patch and minor PRs. |
| [`trigger-push-main.yml`](.github/workflows/trigger-push-main.yml) | push to `main` | Re-runs checks, builds and pushes nightly sha-tagged images, then drift checks them. |
| [`trigger-release.yml`](.github/workflows/trigger-release.yml) | release published | Builds and pushes versioned and `latest` images, drift checks them, and rebuilds the offline image on the new base. |
| [`trigger-vulndb.yml`](.github/workflows/trigger-vulndb.yml) | daily schedule | Refreshes the offline image when the vulnerability database changes. |
| [`badges.yml`](.github/workflows/badges.yml) | after release / DB refresh, daily | Publishes the image-size badge JSON to the `badges` branch. |

| Reusable unit | Purpose |
| --- | --- |
| [`ci-build.yml`](.github/workflows/ci-build.yml) | Build full and slim images for amd64 and arm64 on native runners, smoke test, optionally push with multi-arch manifests. |
| [`ci-test.yml`](.github/workflows/ci-test.yml) | Run the govulncheck action against a scenario and assert the expected advisories. |
| [`ci-lint.yml`](.github/workflows/ci-lint.yml) | hadolint, shellcheck, and actionlint in parallel. |
| [`ci-secret-scan.yml`](.github/workflows/ci-secret-scan.yml) | gitleaks over the PR or push commit range. |
| [`ci-offline.yml`](.github/workflows/ci-offline.yml) | Rebuild the offline image when the vuln database changes, validated air-gapped before push. |

Shared logic lives in composite actions: [`go-version`](.github/actions/go-version) resolves the Go
version from `go.mod`, [`go-setup-cache`](.github/actions/go-setup-cache) sets up Go with a keyed
module and build cache, and [`govulncheck-eval`](.github/actions/govulncheck-eval) is the drift check
that the push, release, and offline drift jobs build on.

## Roadmap

- Publish the remaining scanners listed under [Status](#status)
- SARIF output and GitHub Security integration
- Pull request reporting through a bot

## Contributing

Issues and pull requests are welcome. If you are adding a tool, please follow the container, action,
workflow flow described above and include a scenario that exercises it. A good rule of thumb is that a
new image should ship with a drift check or an equivalent test proving it matches the upstream tool.

## License

Released under the [MIT License](LICENSE).

Third party tools and data we package or invoke keep their own licenses, listed in
[THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md). Note that the offline image bundles the Go
Vulnerability Database, whose entries are licensed [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/)
and attributed to The Go Authors, and which aggregates data from the CVE database and the GitHub
Advisory Database.

## Maintainer

Built and maintained by [Askrella](https://askrella.de), a software company based in Germany building
company suites, API driven services, and custom software.
