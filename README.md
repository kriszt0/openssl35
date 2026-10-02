# openssl35 RPM kit (RHEL 7, /opt/openssl35)

A zip tartalmazza az OpenSSL 3.5.9 forrást (SHA256 rögzítve a `pkg.env`-ben), a spec-et és a build scripteket.
Git/Gitea nem kell.

## RPM építése (egy Linux gépen, ahol van podman)
    unzip openssl35-rpm-kit.zip && cd openssl35-rpm-kit
    ./build.sh
Eredmény: `out/openssl35-3.5.9-1.el7*.x86_64.rpm`, `out/*.src.rpm`, `out/SHA256SUMS`.
A build offline konténerben fut (Oracle Linux 7), majd egy tiszta ubi7 konténerben telepítés + TLS 1.3 teszt.
Első futásnál a konténer image-ek letöltése és a builder felépítése ~pár perc.

## Aláírással (ajánlott)
    gpg --batch --passphrase '' --quick-generate-key "openssl35 RPM signing <devops@example.com>" rsa4096 sign 2y
    FPR=$(gpg --list-keys --with-colons devops@example.com | awk -F: '/^fpr:/ {print $10; exit}')
    gpg --armor --export-secret-keys "$FPR" > signing.key.asc
    gpg --armor --export "$FPR" > RPM-GPG-KEY-openssl35.pub
    RPM_SIGNING_KEY_FILE=signing.key.asc RPM_PUBKEY_FILE=RPM-GPG-KEY-openssl35.pub ./build.sh
A `signing.key.asc`-t utána tedd jelszókezelőbe, a gépről töröld.

## Telepítés a RHEL 7 szerveren
    scp out/openssl35-*.x86_64.rpm out/SHA256SUMS user@szerver:/tmp/
    # a szerveren:
    cd /tmp && sha256sum -c SHA256SUMS --ignore-missing
    sudo rpm --import RPM-GPG-KEY-openssl35.pub      # ha aláírt; a kulcsot külön csatornán add át
    rpm -K openssl35-*.x86_64.rpm
    sudo yum localinstall openssl35-*.x86_64.rpm
    /opt/openssl35/bin/openssl version

## Forrás hitelesítése (egyszeri, ajánlott)
A zipben lévő `.sha256` ugyanonnan van, mint a tarball, ezért ellenőrizd az `.asc` aláírást az openssl.org-on
közölt kiadási kulccsal: `gpg --verify openssl-3.5.9.tar.gz.asc openssl-3.5.9.tar.gz`.

## Új verzió
Cseréld a tarballt, és írd át a `pkg.env`-ben: VERSION, TARBALL, SHA256.

## Image források (nincs Docker Hub)
Az alapértelmezett build image: `container-registry.oracle.com/os/oraclelinux:7` (Oracle Container Registry, bejelentkezés nélkül).
A verify image: `registry.access.redhat.com/ubi7/ubi` (Red Hat registry).
Más forrás (pl. belső mirror) megadása:
    BUILD_BASE_IMAGE=ghcr.io/oracle/oraclelinux:7-slim ./build.sh
    BUILD_BASE_IMAGE=registry.cegnev.local/oraclelinux:7 VERIFY_IMAGE=registry.cegnev.local/ubi7/ubi ./build.sh
Mindig teljes (registry-vel kezdődő) nevet adj meg, különben a podman a registries.conf szerint találgat.
