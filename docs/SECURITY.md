# Security model

1. SHA-256 is the required cryptographic integrity control.
2. SHA-1 is emitted only as legacy audit evidence and must never be the sole trust decision.
3. Production builds require pinned approved source checksums.
4. RPM authenticity uses an organizational GPG/RPM signing key. X.509 TLS certificates do not replace RPM signatures.
5. Keep the RPM private key outside Git and outside build artifacts; prefer Key Vault/HSM or a protected signing agent.
6. HTTPS distribution uses the company's X.509 server certificate/CA.
7. The package is isolated under /opt/company/openssl and does not overwrite the OL7 system OpenSSL.
8. Production signing is a separate Azure DevOps environment with approvals/checks.
9. Keep Pipeline Artifacts according to the organization's audit retention policy.
10. Satellite should import the public RPM signing key and enforce GPG verification.
