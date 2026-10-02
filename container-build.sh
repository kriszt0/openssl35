#!/usr/bin/env bash
# A build konténeren BELÜL fut (hálózat nélkül): rpmbuild + opcionális aláírás.
set -euo pipefail
: "${NAME:?}" "${VERSION:?}" "${RELEASE:?}" "${PREFIX:?}"
TOP=/root/rpmbuild

rpmbuild -ba "$TOP/SPECS/$NAME.spec" \
    --define "_topdir $TOP" \
    --define "openssl_version $VERSION" \
    --define "pkg_release $RELEASE" \
    --define "ossl_prefix $PREFIX"

if [[ -n "${RPM_SIGNING_KEY:-}" ]]; then
    echo ">> RPM aláírás"
    export GNUPGHOME; GNUPGHOME="$(mktemp -d)"; chmod 700 "$GNUPGHOME"
    trap 'gpg-connect-agent killagent /bye >/dev/null 2>&1 || true; rm -rf "$GNUPGHOME"' EXIT
    printf '%s\n' "$RPM_SIGNING_KEY" | gpg --batch --quiet --import
    FPR="$(gpg --batch --with-colons --list-secret-keys | awk -F: '/^fpr:/ {print $10; exit}')"
    [[ -n "$FPR" ]] || { echo "HIBA: nem található titkos kulcs" >&2; exit 1; }
    rpmsign --addsign \
        --define "_gpg_name $FPR" \
        --define "_gpg_path $GNUPGHOME" \
        "$TOP"/RPMS/x86_64/*.rpm "$TOP"/SRPMS/*.rpm
else
    echo ">> FIGYELEM: RPM_SIGNING_KEY nincs megadva, az RPM alá NEM lesz írva"
fi
