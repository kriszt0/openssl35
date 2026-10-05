# Key handling

## Upstream OpenSSL verification

Create a dedicated GNUPGHOME and import only the public OpenSSL release-signing key obtained through an independently trusted channel.

Example:

    mkdir -m 700 keys/upstream-gnupg
    GNUPGHOME=$PWD/keys/upstream-gnupg gpg --import approved-openssl-release-key.asc
    GNUPGHOME=$PWD/keys/upstream-gnupg gpg --fingerprint

Put the exact approved full fingerprint into `config/security.env`.

Do not automatically trust a public key fetched from the same location as the source archive.

## RPM signing

Use an organizational OpenPGP key approved for RPM signing.

Preferred production patterns:
- dedicated hardened signing host
- HSM-backed signing service
- offline signing step

The private key must not be committed, copied into the build container, published in artifacts, or embedded in the RPM.

Only the public key may be published as:
    repo/RPM-GPG-KEY-COMPANY
