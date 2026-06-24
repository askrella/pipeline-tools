# Offline variant: the slim image plus a bundled copy of the Go vulnerability
# database, for sandboxes with no WAN egress. Built FROM the published slim
# image and adding ONLY the DB as a new layer, so the registry deduplicates the
# shared base layers and stores just the ~2.3 MB DB blob (identical across
# architectures). The image is run with `-db file:///opt/vulndb` so govulncheck
# never reaches the network for advisories.
#
# The DB goes stale, so this is published under a rolling tag (latest-slim-offline)
# that is overwritten whenever the database changes. It is intentionally NOT
# pinnable. See ci-offline.yml.
ARG BASE=ghcr.io/askrella/pipeline-tools/govulncheck:latest-slim
FROM ${BASE}

# Populated by the build by unzipping https://vuln.go.dev/vulndb.zip (v1 schema:
# index/ and ID/ at the root).
COPY vulndb/ /opt/vulndb/

# Bundled SBOM (SPDX JSON), so air-gapped consumers that cannot fetch the
# registry attestation still have a machine-readable bill of materials. ci-offline
# generates this with Syft; the same SBOM is also attested on the pushed image.
COPY sbom/ /usr/share/sbom/

# The DB's own modified timestamp, used by ci-offline.yml to decide whether the
# published image is already current (read back via crane).
ARG VULNDB_MODIFIED=unknown
LABEL de.askrella.vulndb.modified="${VULNDB_MODIFIED}"
LABEL org.opencontainers.image.description="govulncheck slim with bundled Go vuln DB (offline, not pinnable)"
# The bundled database entries are CC-BY-4.0 and require attribution wherever the
# data is redistributed. See THIRD_PARTY_LICENSES.md.
LABEL org.opencontainers.image.licenses="MIT AND BSD-3-Clause AND GPL-2.0 AND CC-BY-4.0"
LABEL de.askrella.vulndb.attribution="Go Vulnerability Database (https://vuln.go.dev), (c) The Go Authors, CC-BY-4.0. Includes data from the CVE database (cve.org) and the GitHub Advisory Database (CC-BY-4.0). See THIRD_PARTY_LICENSES.md"
LABEL de.askrella.sbom.path="/usr/share/sbom"

# The slim base already runs as uid 10001; the DB and SBOM above are copied as
# root at build time and are world-readable. Re-assert non-root for clarity.
USER 10001
