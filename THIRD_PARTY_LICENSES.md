# Third Party Licenses

Pipeline Tools packages and invokes a number of third party tools and data sets.
This file lists them and their licenses. It is grouped by how each component
reaches you, because that is what determines the obligations: components we
**redistribute inside our images** matter most, tools we only **invoke in CI**
are never shipped to you, and the **GitHub Actions** are build time dependencies.

Nothing here changes the license of Pipeline Tools itself, which is
[MIT](LICENSE).

## Bundled in the published container images

These are redistributed as part of `ghcr.io/askrella/pipeline-tools/govulncheck`.

| Component | Used for | License |
| --- | --- | --- |
| [govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) (`golang.org/x/vuln`) | The scanner binary | [BSD-3-Clause](https://github.com/golang/vuln/blob/master/LICENSE) |
| stackrox-scanner (`golang.org/x/vuln/.../stackrox-scanner`) | Integration binary | [BSD-3-Clause](https://github.com/golang/vuln/blob/master/LICENSE) |
| [Go toolchain and standard library](https://go.dev) | Bundled so govulncheck can analyze modules | [BSD-3-Clause](https://github.com/golang/go/blob/master/LICENSE) |
| [Alpine Linux](https://www.alpinelinux.org/) base (`alpine`) | Base of the full image | [MIT](https://gitlab.alpinelinux.org/alpine/aports) and components below |
| musl libc | C library in the Alpine base | [MIT](https://git.musl-libc.org/cgit/musl/tree/COPYRIGHT) |
| BusyBox | Userland in the Alpine base | [GPL-2.0](https://www.busybox.net/license.html) |
| git | Used by govulncheck for module resolution | [GPL-2.0](https://github.com/git/git/blob/master/COPYING) |

### Vulnerability database (offline image only)

The `latest-slim-offline` image bundles the Go vulnerability database
(`https://vuln.go.dev`). The database **entries** are licensed separately from
the tooling:

> The Go Vulnerability Database is licensed under the
> [Creative Commons Attribution 4.0 License](https://creativecommons.org/licenses/by/4.0/),
> copyright The Go Authors.

The Go Vulnerability Database aggregates information from upstream sources, which
carry their own terms and must also be credited:

- The Common Vulnerabilities and Exposures (CVE) database, see the
  [CVE Terms of Use](https://www.cve.org/Legal/TermsOfUse).
- The [GitHub Advisory Database](https://github.com/advisories), licensed under
  [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/).

CC-BY-4.0 requires attribution wherever the data is redistributed, which is why
the offline image carries this attribution as an image label and why it is
restated here. See [go.dev/security/vuln/database](https://go.dev/security/vuln/database).

## Tools invoked in CI (not redistributed)

These run during our pipelines and are never shipped in an image, so their
licenses impose no obligations on what you pull. The two GPL tools are invoked as
separate, unmodified executables (not linked into or distributed with our code),
so their copyleft terms do not extend to this project.

| Tool | Used for | License |
| --- | --- | --- |
| [docker-slim / slimtoolkit](https://github.com/slimtoolkit/slim) | Building the slim image | [Apache-2.0](https://github.com/slimtoolkit/slim/blob/master/LICENSE) |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scanning | [MIT](https://github.com/gitleaks/gitleaks/blob/master/LICENSE) |
| [hadolint](https://github.com/hadolint/hadolint) | Dockerfile linting | [GPL-3.0](https://github.com/hadolint/hadolint/blob/master/LICENSE) |
| [ShellCheck](https://github.com/koalaman/shellcheck) | Shell script linting | [GPL-3.0](https://github.com/koalaman/shellcheck/blob/master/LICENSE) |
| [actionlint](https://github.com/rhysd/actionlint) | Workflow linting | [MIT](https://github.com/rhysd/actionlint/blob/main/LICENSE.txt) |
| [crane / go-containerregistry](https://github.com/google/go-containerregistry) | Reading image metadata | [Apache-2.0](https://github.com/google/go-containerregistry/blob/main/LICENSE) |
| [Syft](https://github.com/anchore/syft) | Generating SBOMs (runs locally, no data upload) | [Apache-2.0](https://github.com/anchore/syft/blob/main/LICENSE) |

## GitHub Actions used in workflows

Build time dependencies referenced by SHA in our workflows.

| Action | License |
| --- | --- |
| [actions/checkout](https://github.com/actions/checkout) | [MIT](https://github.com/actions/checkout/blob/main/LICENSE) |
| [actions/setup-go](https://github.com/actions/setup-go) | [MIT](https://github.com/actions/setup-go/blob/main/LICENSE) |
| [actions/cache](https://github.com/actions/cache) | [MIT](https://github.com/actions/cache/blob/main/LICENSE) |
| [actions/upload-artifact](https://github.com/actions/upload-artifact) | [MIT](https://github.com/actions/upload-artifact/blob/main/LICENSE) |
| [actions/download-artifact](https://github.com/actions/download-artifact) | [MIT](https://github.com/actions/download-artifact/blob/main/LICENSE) |
| [docker/login-action](https://github.com/docker/login-action) | [Apache-2.0](https://github.com/docker/login-action/blob/master/LICENSE) |
| [docker/setup-buildx-action](https://github.com/docker/setup-buildx-action) | [Apache-2.0](https://github.com/docker/setup-buildx-action/blob/master/LICENSE) |
| [dependabot/fetch-metadata](https://github.com/dependabot/fetch-metadata) | [MIT](https://github.com/dependabot/fetch-metadata/blob/main/LICENSE) |
| [anchore/sbom-action](https://github.com/anchore/sbom-action) | [Apache-2.0](https://github.com/anchore/sbom-action/blob/main/LICENSE) |
| [actions/attest-sbom](https://github.com/actions/attest-sbom) | [MIT](https://github.com/actions/attest-sbom/blob/main/LICENSE) |

## Future tools

The scanners on our roadmap (golangci-lint, gosec, tfsec, terrascan, checkov)
are not published yet and are therefore not listed above. Each will be added here
when its image ships.

## Corrections

If anything here is inaccurate or out of date, please open an issue or pull
request.
