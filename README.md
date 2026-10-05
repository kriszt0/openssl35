# OpenSSL 3.5.x RPM Artifact Factory — Oracle Linux 7

Azure-independent production-oriented build repository.

## Security model

- OpenSSL is installed side-by-side under `/opt/openssl35`.
- The Oracle Linux 7 system OpenSSL is never replaced.
- SHA-256 is an integrity control.
- SHA-1 is generated only as legacy audit evidence.
- Production source builds require a pinned, independently approved SHA-256.
- Upstream OpenPGP verification is supported and can be required.
- RPMs are signed with an organizational OpenPGP/RPM signing key.
- Private signing keys are never stored in this repository or release artifacts.
- Builds and tests run in Podman containers.
- The final release contains checksums, manifests, provenance and logs.

## Host prerequisites

A supported Linux build host with:

    podman
    bash
    curl
    sha256sum
    sha1sum
    gpg
    make

The host itself does not need to be Oracle Linux 7. The target build/test environment is OL7.

## First-time configuration

1. Set the required version in `VERSION`.
2. Copy `config/checksums/3.5.9.env.example` to `config/checksums/3.5.9.env`.
3. Fill `SOURCE_SHA256` from independently approved official OpenSSL release evidence.
4. If your policy requires SHA-1 reference comparison, fill `SOURCE_SHA1`; otherwise SHA-1 is still generated as evidence.
5. Import/approve the upstream OpenSSL release signing public key into a dedicated GPG keyring and set its fingerprint in `config/security.env`.
6. Configure your organizational RPM signing key outside Git. See `keys/README.md`.
7. Replace `repo.example.company` in `config/repository.env`.

## Offline fallback

If upstream cannot be reached, place one exact source file in `download/`:

    openssl-3.5.9.tar.gz
    openssl-3.5.9.zip

The original input is hashed before any normalization. ZIP input is converted to a deterministic build tarball, and both the original input and normalized build source are recorded.

## Commands

Preflight:

    make preflight

Fetch and verify only:

    make source

Build:

    make build

Test:

    make test

Create unsigned release evidence:

    make evidence

Sign RPMs (requires external signing key):

    make sign

Verify signatures:

    make verify-rpm

Create YUM repository:

    make repo

Complete release:

    make release

For an unsigned non-production development run:

    ALLOW_UNSIGNED=1 make dev-release

## Version upgrade

For a new patch release:

    echo 3.5.10 > VERSION
    cp config/checksums/3.5.9.env.example config/checksums/3.5.10.env

Then insert the independently approved upstream digest(s) and run:

    make release

No URL, RPM filename or installation prefix needs a version-specific manual edit.

## Result

`release/openssl-<version>/` contains RPM/SRPM, source evidence, SHA-256/SHA-1 files, manifest, provenance, test logs, public signing key (if configured), and generated YUM repository.

## Server installation

Direct RPM:

    sudo rpm --import RPM-GPG-KEY-COMPANY
    sudo yum localinstall -y openssl35-<version>-1.el7.x86_64.rpm

YUM repository:

    sudo rpm --import https://repo.example.company/openssl35/RPM-GPG-KEY-COMPANY
    sudo curl --fail --proto '=https' --tlsv1.2 \
      -o /etc/yum.repos.d/openssl35.repo \
      https://repo.example.company/openssl35/openssl35.repo
    sudo yum install -y openssl35

Satellite can ingest the signed RPMs/repository content from the release directory.

## Production notes

Oracle Linux 7 is an old target. Keep the build host, Podman and signing infrastructure on a supported OS.
Pin container images by digest in your internal registry before production use. `config/images.env` deliberately contains replace-me digest fields.
Use an internal mirror if public registries are not acceptable.
