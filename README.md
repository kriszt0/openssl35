# openssl35 RPM pipeline (Gitea Actions)

OpenSSL 3.5 RPM RHEL 7-re, telepítés: `/opt/openssl35`. Build: OL7 konténer (offline), verify: ubi7 konténer (offline), artifact: `rpm-package-openssl35`.

## Egyszeri beállítás
1. `packaging/pkgs/openssl35.env`: írd be a hivatalos kiadás SHA256-ját (`SHA256=`). Placeholderrel a pipeline szándékosan elbukik.
2. Runner: host-mode `act_runner`, rajta `podman`, `git`, `node`. A label legyen a `BUILD_RUNNER` repo változó (alapértelmezett: `rpm-build-host`).
3. (Ajánlott) RPM aláírás:
   ```
   gpg --batch --passphrase '' --quick-generate-key "openssl35 RPM signing <devops@example.com>" rsa4096 sign 2y
   gpg --armor --export-secret-keys <FPR>   # -> Gitea secret: RPM_SIGNING_KEY
   gpg --armor --export <FPR> > packaging/RPM-GPG-KEY-openssl35.pub   # commitold a repóba
   ```
   RSA kulcs kell (az el7 rpm nem ismeri az ed25519-et). A pubkey fájl jelenléte után a pipeline aláírás nélkül elbukik.
4. (Opcionális) `BUILD_BASE_IMAGE` / `VERIFY_IMAGE` repo változók: image-ek digestre pinnelve (`...@sha256:...`).
5. (Opcionális) Gitea RPM registry: `PUBLISH_RPM=true` változó + `PACKAGES_USER`, `PACKAGES_TOKEN` secretek, majd tag push: `git tag openssl35-3.5.9-1 && git push --tags`.

## Futtatás
Gitea UI -> Actions -> build-rpm -> Run workflow (vagy tag push). Az artifact az Actions futás alján tölthető le.

## Telepítés a hoston
```
sha256sum -c SHA256SUMS
sudo rpm --import RPM-GPG-KEY-openssl35.pub     # egyszer, külön csatornán kapott kulcs
rpm -K openssl35-*.x86_64.rpm
sudo yum localinstall openssl35-*.x86_64.rpm
/opt/openssl35/bin/openssl version
```

## Verzióváltás
`openssl35.env`: VERSION, TARBALL, SOURCE_URL, SHA256, (RELEASE nullázás/növelés) -> commit -> futtatás.

## Megjegyzés
Nem futtattam éles környezetben; az első futásnál a build/verify logokat érdemes végignézni.
