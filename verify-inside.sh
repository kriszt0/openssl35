#!/usr/bin/env bash
set -euo pipefail
: "${NAME:?}" "${VERSION:?}" "${PREFIX:?}"
fail() { echo "VERIFY FAIL: $*" >&2; exit 1; }
cd /rpms
shopt -s nullglob
rpms=( ${NAME}-${VERSION}-*.x86_64.rpm )
[[ ${#rpms[@]} -eq 1 ]] || fail "pontosan egy bináris rpm kell, van: ${#rpms[@]}"
RPM="${rpms[0]}"
O="$PREFIX/bin/openssl"

echo "== checksum";  sha256sum -c SHA256SUMS

echo "== aláírás"
[[ -f RPM-GPG-KEY.pub ]] && rpm --import RPM-GPG-KEY.pub
sig="$(rpm -K "$RPM")"; echo "$sig"
if [[ "${EXPECT_SIGNED:-0}" == 1 ]]; then
    grep -Eqi '(pgp|gpg)' <<<"$sig"           || fail "az RPM nincs aláírva"
    if grep -Eqi 'NOT OK|NOKEY|BAD' <<<"$sig"; then fail "aláírás érvénytelen"; fi
fi

echo "== telepítés (scriptlet-ekkel, --nodeps nélkül)"
rpm -ivh "$RPM"
out="$(rpm -V "$NAME")"; [[ -z "$out" ]] || fail "rpm -V eltérés: $out"

echo "== csomag higiénia"
bad="$(rpm -ql "$NAME" | grep -v "^$PREFIX" || true)";             [[ -z "$bad" ]]  || fail "prefixen kívüli fájl: $bad"
leak="$(rpm -q --provides "$NAME" | grep -E 'libssl|libcrypto' || true)"; [[ -z "$leak" ]] || fail "szivárgó Provides: $leak"

echo "== futtatás"
"$O" version | tee /dev/stderr | grep -q "OpenSSL $VERSION" || fail "rossz verzió"
ldd "$O" | tee /dev/stderr
if ldd "$O" | grep -q 'not found'; then fail "hiányzó lib"; fi
ldd "$O" | grep -E 'lib(ssl|crypto)\.so' | grep -vq "$PREFIX" && fail "lib a prefixen kívülről töltődik"
/usr/bin/openssl version | grep -q 'OpenSSL 1.0.2' || fail "a rendszer openssl megváltozott"
"$O" list -kem-algorithms | grep -qi 'ML-KEM' || fail "ML-KEM hiányzik"
test -s "$PREFIX/ssl/cert.pem" || fail "CA bundle hiányzik"

echo "== loopback TLS 1.3 handshake"
T="$(mktemp -d)"
"$O" req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
    -keyout "$T/k.pem" -out "$T/c.pem" -subj /CN=localhost \
    -addext subjectAltName=DNS:localhost -days 1 2>/dev/null
"$O" s_server -accept 127.0.0.1:14433 -cert "$T/c.pem" -key "$T/k.pem" -tls1_3 -naccept 1 -quiet >/dev/null 2>&1 &
SP=$!; sleep 1
echo hi | "$O" s_client -connect 127.0.0.1:14433 -tls1_3 -CAfile "$T/c.pem" \
    -verify_hostname localhost -verify_return_error -brief >"$T/out" 2>&1 || true
wait "$SP" 2>/dev/null || true
cat "$T/out"
grep -q 'TLSv1.3' "$T/out" || fail "TLS 1.3 handshake sikertelen"

echo "VERIFY OK: $RPM"
