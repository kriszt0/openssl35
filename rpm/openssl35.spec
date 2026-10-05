Name:           openssl35
Version:        %{openssl_version}
Release:        1%{?dist}
Summary:        Isolated OpenSSL %{version} for Oracle Linux 7

License:        Apache-2.0
URL:            https://www.openssl.org/
Source0:        openssl-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  perl
BuildRequires:  perl-core
BuildRequires:  zlib-devel
BuildRequires:  binutils

%global install_root /opt/openssl35

# Number of parallel build jobs.
# build-rpm.sh normally supplies:
#   --define "build_jobs <N>"
%{!?build_jobs:%global build_jobs 1}


%description
Isolated OpenSSL %{version} installation for Oracle Linux 7.

The package is installed under /opt/openssl35 and does not replace
the operating system OpenSSL package, binaries or libraries.

The package contains its own OpenSSL shared libraries:
libssl.so.3 and libcrypto.so.3.


%prep
%setup -q -n openssl-%{version}


%build

echo "========================================"
echo " OpenSSL build configuration"
echo "========================================"
echo "Version    : %{version}"
echo "Prefix     : %{install_root}"
echo "Library dir: %{install_root}/lib64"
echo "Build jobs : %{build_jobs}"
echo "========================================"

#
# Runtime library path:
#
# /opt/openssl35/bin/openssl
#             |
#             +--> $ORIGIN/../lib64
#                       |
#                       +--> /opt/openssl35/lib64
#
# $ORIGIN is evaluated by the ELF dynamic loader at runtime.
#
export LDFLAGS="-Wl,-rpath,\$ORIGIN/../lib64"

./Configure linux-x86_64 \
    --prefix=%{install_root} \
    --openssldir=%{install_root}/ssl \
    --libdir=lib64 \
    shared \
    zlib

echo
echo "========================================"
echo " Building OpenSSL"
echo "========================================"

make -j%{build_jobs}


echo
echo "========================================"
echo " Running OpenSSL upstream tests"
echo "========================================"

make test -j%{build_jobs}


%install

rm -rf %{buildroot}

echo
echo "========================================"
echo " Installing into RPM buildroot"
echo "========================================"

make install_sw install_ssldirs DESTDIR=%{buildroot}


#
# Remove helper scripts which would otherwise introduce:
#
#   perl(WWW::Curl::Easy)
#
# as an RPM runtime dependency.
#
rm -f %{buildroot}%{install_root}/ssl/misc/tsget
rm -f %{buildroot}%{install_root}/ssl/misc/tsget.pl


echo
echo "========================================"
echo " OpenSSL installation validation"
echo "========================================"

echo
echo "Buildroot:"
echo "%{buildroot}"

echo
echo "OpenSSL executable:"
ls -la %{buildroot}%{install_root}/bin/openssl


echo
echo "========================================"
echo " OpenSSL libraries"
echo "========================================"

find %{buildroot}%{install_root} \
    \( -name 'libssl.so*' -o -name 'libcrypto.so*' \) \
    -ls


echo
echo "========================================"
echo " ELF dynamic section"
echo "========================================"

readelf -d %{buildroot}%{install_root}/bin/openssl || true


echo
echo "========================================"
echo " RPATH / RUNPATH"
echo "========================================"

readelf -d %{buildroot}%{install_root}/bin/openssl | \
    grep -E 'RPATH|RUNPATH' || true


echo
echo "========================================"
echo " Required file validation"
echo "========================================"

if [ ! -x %{buildroot}%{install_root}/bin/openssl ]; then
    echo "ERROR: OpenSSL executable missing:"
    echo "%{install_root}/bin/openssl"
    exit 1
fi


if [ ! -f %{buildroot}%{install_root}/lib64/libssl.so.3 ]; then
    echo "ERROR: libssl.so.3 missing"
    echo
    echo "Libraries actually installed:"
    find %{buildroot}%{install_root} -name 'libssl.so*' -ls
    exit 1
fi


if [ ! -f %{buildroot}%{install_root}/lib64/libcrypto.so.3 ]; then
    echo "ERROR: libcrypto.so.3 missing"
    echo
    echo "Libraries actually installed:"
    find %{buildroot}%{install_root} -name 'libcrypto.so*' -ls
    exit 1
fi


echo
echo "========================================"
echo " Required OpenSSL files OK"
echo "========================================"


%files

%license LICENSE.txt
%doc README.md

/opt/openssl35


%changelog
* Mon Oct 05 2026 Company Build Engineering <build@example.company> - 3.5.9-1
- Install OpenSSL under /opt/openssl35
- Keep OpenSSL isolated from operating system OpenSSL
- Package private libssl.so.3 and libcrypto.so.3
- Configure private runtime library search path
- Remove tsget WWW::Curl::Easy dependency