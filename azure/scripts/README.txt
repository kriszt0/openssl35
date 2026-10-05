# OpenSSL 3.5 Enterprise RPM

Enterprise build pipeline for OpenSSL 3.5 RPM packages.

The package is installed under:

    /opt/openssl35

The operating system OpenSSL installation is not replaced.


## Current release

    openssl-3.5.9


## Build

The pipeline is manually triggered.

Azure DevOps:

    Run pipeline

Parameter:

    OpenSSL Git tag

Default:

    openssl-3.5.9


## Example

For OpenSSL 3.5.9:

    openssl-3.5.9


For the next approved version:

    openssl-3.5.10


No source-code change is required for a version change.


## Pipeline stages

    Build
      |
      +-- Checkout source
      |
      +-- Verify Git tag
      |
      +-- Build RPM
      |
      +-- Validate RPM
      |
      +-- Generate SHA1
      |
      +-- Generate SHA256
      |
      +-- Generate metadata
      |
      +-- Generate SBOM
      |
      v
    Sign
      |
      +-- Import GPG signing key
      |
      +-- Sign RPM
      |
      +-- Verify RPM signature
      |
      +-- Generate final checksums
      |
      +-- Create evidence bundle
      |
      v
    Release


## Evidence

Each release contains:

    RPM
    SHA1SUM
    SHA256SUM
    BUILDINFO.txt
    build-metadata.json
    SBOM.cyclonedx.json


## Audit information

The build metadata records:

    Git tag
    Git commit
    Source repository
    Azure Build ID
    Azure Build Number
    Azure Source Version
    Build timestamp
    Build agent
    SHA1
    SHA256


## RPM signing

RPM packages are signed using the company's GPG RPM signing key.

The private signing key must never be committed to Git.

The private key is stored as an Azure DevOps Secure File.


## Installation

The package is intended to be distributed through Red Hat Satellite.

Example:

    dnf install openssl35


The RPM installs:

    /opt/openssl35


## Verification

RPM signature:

    rpm -Kv openssl35-*.rpm

SHA256:

    sha256sum -c SHA256SUM

SHA1:

    sha1sum -c SHA1SUM