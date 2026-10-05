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

# build-rpm.sh supplies this with:
#
#   --define "build_jobs N"
#
# Default: 1
%{!?build_jobs:%global build_jobs 1}


%description
Isolated OpenSSL %{version} installation for Oracle Linux 7.

The package is installed under /opt/openssl35 and does not replace
the operating system OpenSSL package, binaries or libraries.

The package contains its own OpenSSL shared libraries under
/opt/openssl35/lib64.

The OpenSSL executable uses a relative ELF RUNPATH so that it loads
libssl.so.3 and libcrypto.so.3 from the package itself without
requiring LD_LIBRARY_PATH or global ld.so configuration.


%prep
%setup -q -n openssl-%{version}


%build

echo
echo "========================================"
echo " OpenSSL build configuration"
echo "========================================"
echo "Version     : %{version}"
echo "Prefix      : %{install_root}"
echo "Library dir : %{install_root}/lib64"
echo "Build jobs  : %{build_jobs}"
echo "========================================"
echo

#
# Build shared OpenSSL libraries.
#
# The literal runtime path must be:
#
#   $ORIGIN/../lib64
#
# For /opt/openssl35/bin/openssl this resolves to:
#
#   /opt/openssl35/lib64
#
# $$ is intentional here. OpenSSL generates Makefiles and the
# additional '$' protects $ORIGIN while passing through make.
#

./Configure linux-x86_64 \
    --prefix=%{install_root} \
    --openssldir=%{install_root}/ssl \
    --libdir=lib64 \
    shared \
    zlib \
    '-Wl,-rpath,$$ORIGIN/../lib64'


echo
echo "========================================"
echo " Building OpenSSL"
echo "========================================"
echo

make -j%{build_jobs}


%install

rm -rf %{buildroot}

echo
echo "========================================"
echo " Installing OpenSSL into RPM buildroot"
echo "========================================"
echo

make install_sw install_ssldirs DESTDIR=%{buildroot}


#
# Remove helper scripts that would introduce an unnecessary
# perl(WWW::Curl::Easy) RPM dependency.
#

rm -f %{buildroot}%{install_root}/ssl/misc/tsget
rm -f %{buildroot}%{install_root}/ssl/misc/tsget.pl


echo
echo "========================================"
echo " Validating RPM buildroot"
echo "========================================"
echo


#
# ----------------------------------------------------------------------
# Executable
# ----------------------------------------------------------------------
#

OPENSSL_BIN="%{buildroot}%{install_root}/bin/openssl"

if [ ! -x "${OPENSSL_BIN}" ]; then
    echo "ERROR: OpenSSL executable is missing"
    echo "Expected:"
    echo "  ${OPENSSL_BIN}"
    exit 1
fi

echo "OpenSSL executable:"
ls -la "${OPENSSL_BIN}"
echo


#
# ----------------------------------------------------------------------
# Private OpenSSL libraries
# ----------------------------------------------------------------------
#

LIBSSL="%{buildroot}%{install_root}/lib64/libssl.so.3"
LIBCRYPTO="%{buildroot}%{install_root}/lib64/libcrypto.so.3"

if [ ! -f "${LIBSSL}" ]; then
    echo "ERROR: private libssl.so.3 is missing"
    echo "Expected:"
    echo "  ${LIBSSL}"
    echo
    echo "Found libssl files:"
    find %{buildroot}%{install_root} -name 'libssl.so*' -ls || true
    exit 1
fi

if [ ! -f "${LIBCRYPTO}" ]; then
    echo "ERROR: private libcrypto.so.3 is missing"
    echo "Expected:"
    echo "  ${LIBCRYPTO}"
    echo
    echo "Found libcrypto files:"
    find %{buildroot}%{install_root} -name 'libcrypto.so*' -ls || true
    exit 1
fi

echo "Private OpenSSL libraries:"
ls -la %{buildroot}%{install_root}/lib64/libssl.so*
ls -la %{buildroot}%{install_root}/lib64/libcrypto.so*
echo


#
# ----------------------------------------------------------------------
# Display ELF dynamic section
# ----------------------------------------------------------------------
#

echo "========================================"
echo " ELF dynamic section"
echo "========================================"
echo

readelf -d "${OPENSSL_BIN}"

echo


#
# ----------------------------------------------------------------------
# RUNPATH / RPATH validation
# ----------------------------------------------------------------------
#

echo "========================================"
echo " RUNPATH validation"
echo "========================================"
echo

RUNPATH="$(
    readelf -d "${OPENSSL_BIN}" 2>/dev/null |
        grep -E '\((RPATH|RUNPATH)\)' || true
)"

echo "Detected:"
echo "${RUNPATH:-<none>}"
echo


if [ -z "${RUNPATH}" ]; then
    echo "ERROR: OpenSSL executable contains no RPATH/RUNPATH"
    echo
    echo 'Required: $ORIGIN/../lib64'
    exit 1
fi


if ! printf '%s\n' "${RUNPATH}" |
    grep -Fq '$ORIGIN/../lib64'
then
    echo "ERROR: OpenSSL executable contains incorrect RPATH/RUNPATH"
    echo
    echo 'Required: $ORIGIN/../lib64'
    echo
    echo "Detected:"
    echo "${RUNPATH}"
    exit 1
fi


echo 'RUNPATH: OK ($ORIGIN/../lib64)'
echo


#
# ----------------------------------------------------------------------
# ELF NEEDED validation
# ----------------------------------------------------------------------
#

echo "========================================"
echo " ELF NEEDED libraries"
echo "========================================"
echo

NEEDED="$(
    readelf -d "${OPENSSL_BIN}" 2>/dev/null |
        grep 'NEEDED' || true
)"

echo "${NEEDED}"
echo


if ! printf '%s\n' "${NEEDED}" |
    grep -Fq 'Shared library: [libssl.so.3]'
then
    echo "ERROR: openssl does not reference libssl.so.3"
    exit 1
fi


if ! printf '%s\n' "${NEEDED}" |
    grep -Fq 'Shared library: [libcrypto.so.3]'
then
    echo "ERROR: openssl does not reference libcrypto.so.3"
    exit 1
fi


echo "ELF dependencies: OK"
echo


#
# ----------------------------------------------------------------------
# Final validation
# ----------------------------------------------------------------------
#

echo "========================================"
echo " OpenSSL RPM validation PASS"
echo "========================================"
echo
echo "Executable:"
echo "  /opt/openssl35/bin/openssl"
echo
echo "Libraries:"
echo "  /opt/openssl35/lib64/libssl.so.3"
echo "  /opt/openssl35/lib64/libcrypto.so.3"
echo
echo "Runtime library path:"
echo '  $ORIGIN/../lib64'
echo


%files
%license LICENSE.txt
%doc README.md

/opt/openssl35


%changelog
* Mon Oct 05 2026 Company Build Engineering <build@example.company> - 3.5.9-1
- Install OpenSSL under /opt/openssl35
- Keep OpenSSL isolated from operating system OpenSSL
- Package private libssl.so.3 and libcrypto.so.3
- Add relative $ORIGIN/../lib64 runtime library path
- Validate OpenSSL ELF RUNPATH during RPM build
- Validate libssl.so.3 and libcrypto.so.3 ELF dependencies
- Remove tsget WWW::Curl::Easy dependency