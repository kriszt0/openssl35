# Production OpenSSL 3.5.x RPM factory

Target: Oracle Linux 7 x86_64. Build orchestration: Azure DevOps. Container engine: Podman.

## Goals
- version is a single Azure pipeline parameter
- upstream GitHub release download with `download/` offline fallback
- pinned SHA-256 verification plus SHA-1 audit evidence
- OL7 container build and clean OL7 installation test
- isolated install under `/opt/company/openssl/<version>`
- GPG-signed RPM
- provenance/audit evidence
- Azure Pipeline Artifact output
- generated YUM repository suitable for HTTPS publication or Satellite ingestion

## First-time setup
1. Use a self-hosted Linux Azure DevOps agent with Podman.
2. Configure `Linux-Podman-Agents` and a protected `Linux-Signing-Agents` pool.
3. Create Azure DevOps environment `openssl-rpm-production-signing` and require approvals/checks.
4. Create/import the organizational RPM GPG signing key. Store private material in an approved secret/HSM process; publish only the public key.
5. Copy `config/checksums.env.example` to `config/checksums.env` and pin approved source digests for each release.
6. Replace `artifacts.example.company` and organization-specific paths.

## Release
Queue `azure-pipelines.yml`, set `opensslVersion=3.5.9`, approve the signing stage, and retrieve artifact `openssl-3.5.9-production`.
For 3.5.10, change only the pipeline parameter to `3.5.10` plus its approved checksum evidence.

## Important
The source checksum values are intentionally not fabricated by this repository. A production release must use values independently approved from the official upstream release evidence.
