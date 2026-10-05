# Operations

## New OpenSSL version
Run the Azure pipeline with parameter `opensslVersion`, e.g. `3.5.10`. No URL/spec change should be required.
Before production publication, approve and pin the official source SHA-256 and requested SHA-1 in `config/checksums.env`.

## Direct RPM verification
```
sha256sum -c SHA256SUMS
sha1sum -c SHA1SUMS
rpm -Kv openssl35-*.rpm
```

## Satellite
Publish/synchronize the generated signed RPM/YUM repository into Satellite, attach it to the appropriate Content View/Lifecycle Environment, then clients use:
```
yum install -y openssl35
```

## HTTPS repository
Publish `out/yum` plus the public signing key through an approved HTTPS endpoint and install the supplied `.repo` definition.

## Runtime
```
/opt/company/openssl/current/bin/openssl version -a
```
