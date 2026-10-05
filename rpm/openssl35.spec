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
#
#   --define "build_jobs <N>"
#
# Default: 1
%{!?build_jobs:%global build_jobs 1}


%description
Isolated OpenSSL %{version} installation for Oracle Linux 7.

The package is installed under /opt/openssl35 and does not replace
the operating system OpenSSL package, binaries or libraries.

The package contains its own OpenSSL shared libraries:
libssl.so.3 and libcrypto.so.3.

The OpenSSL executable uses a relative ELF RUNPATH so that its
OpenSSL libraries are loaded from /opt/openssl35/lib64 without
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
# IMPORTANT:
#
# $ORIGIN is interpreted by the Linux dynamic loader at runtime.
#
# /opt/openssl35/bin/openssl
#
#     $ORIGIN
#        |
#        +-- /opt/openssl35/bin
#                     |
#                     +-- ../lib64
#                            |
#                            +-- /opt/openssl35/lib64
#
# The extra '$' is required so that the generated Makefile preserves
# the literal $ORIGIN value for the linker.
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
echo " Installing into RPM buildroot"
echo "========================================"
echo

make install_sw install_ssldirs DESTDIR=%{buildroot}


#
# Remove helper scripts which would otherwise introduce the unwanted:
#
#   perl(WWW::Curl::Easy)
#
# runtime RPM dependency.
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


#
# ----------------------------------------------------------------------
# OpenSSL executable
# ----------------------------------------------------------------------
#

echo "Checking OpenSSL executable..."

if [ ! -x %{buildroot}%{install_root}/bin/openssl ]; then
    echo
    echo "ERROR: OpenSSL executable missing"
    echo
    echo "Expected:"
    echo "%{install_root}/bin/openssl"
    echo
    exit 1
fi

ls -la %{buildroot}%{install_root}/bin/openssl

echo
echo "OpenSSL executable: OK"


#
# ----------------------------------------------------------------------
# libssl.so.3
# ----------------------------------------------------------------------
#

echo
echo "Checking private libssl.so.3..."

if [ ! -f %{buildroot}%{install_root}/lib64/libssl.so.3 ]; then
    echo
    echo "ERROR: libssl.so.3 missing"
    echo
    echo "Expected:"
    echo "%{install_root}/lib64/libssl.so.3"
    echo
    echo "Libraries actually installed:"
    find %{buildroot}%{install_root} \
        -name 'libssl.so*' \
        -ls || true
    echo
    exit 1
fi

ls -la %{buildroot}%{install_root}/lib64/libssl.so*

echo
echo "libssl.so.3: OK"


#
# ----------------------------------------------------------------------
# libcrypto.so.3
# ----------------------------------------------------------------------
#

echo
echo "Checking private libcrypto.so.3..."

if [ ! -f %{buildroot}%{install_root}/lib64/libcrypto.so.3 ]; then
    echo
    echo "ERROR: libcrypto.so.3 missing"
    echo
    echo "Expected:"
    echo "%{install_root}/lib64/libcrypto.so.3"
    echo
    echo "Libraries actually installed:"
    find %{buildroot}%{install_root} \
        -name 'libcrypto.so*' \
        -ls || true
    echo
    exit 1
fi

ls -la %{buildroot}%{install_root}/lib64/libcrypto.so*

echo
echo "libcrypto.so.3: OK"


#
# ----------------------------------------------------------------------
# Show all packaged OpenSSL libraries
# ----------------------------------------------------------------------
#

echo
echo "========================================"
echo " Installed OpenSSL libraries"
echo "========================================"
echo

find %{buildroot}%{install_root}/lib64 \
    \( -name 'libssl.so*' -o -name 'libcrypto.so*' \) \
    -ls


#
# ----------------------------------------------------------------------
# ELF dynamic information
# ----------------------------------------------------------------------
#

echo
echo "========================================"
echo " OpenSSL ELF dynamic section"
echo "========================================"
echo

readelf -d %{buildroot}%{install_root}/bin/openssl


#
# ----------------------------------------------------------------------
# Mandatory RUNPATH validation
# ----------------------------------------------------------------------
#

echo
echo "========================================"
echo " RUNPATH validation"
echo "========================================"
echo

RUNPATH="$(
    readelf -d %{buildroot}%{install_root}/bin/openssl | \
        grep -E 'RPATH|RUNPATH' || true
)"

echo "Detected RPATH/RUNPATH:"
echo "${RUNPATH}"
echo

if [ -z "${RUNPATH}" ]; then
    echo "ERROR: OpenSSL executable contains no RPATH/RUNPATH"
    echo
    echo "Required:"
    echo "\$ORIGIN/../lib64"
    echo
    exit 1
fi

echo "${RUNPATH}" | grep -Fq '$ORIGIN/../lib64'

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: OpenSSL executable contains incorrect RUNPATH"
    echo
    echo "Required:"
    echo "\$ORIGIN/../lib64"
    echo
    echo "Detected:"
    echo "${RUNPATH}"
    echo
    exit 1
fi

echo "RUNPATH: OK"


#
# ----------------------------------------------------------------------
# Verify NEEDED libraries
# ----------------------------------------------------------------------
#

echo
echo "========================================"
echo " ELF NEEDED libraries"
echo "========================================"
echo

readelf -d %{buildroot}%{install_root}/bin/openssl | \
    grep NEEDED || true


#
# openssl should dynamically reference libssl.so.3 and libcrypto.so.3.
#

readelf -d %{buildroot}%{install_root}/bin/openssl | \
    grep 'Shared library: \[libssl.so.3\]' >/dev/null || {
        echo
        echo "ERROR: openssl does not reference libssl.so.3"
        exit 1
    }

readelf -d %{buildroot}%{install_root}/bin/openssl | \
    grep 'Shared library: \[libcrypto.so.3\]' >/dev/null || {
        echo
        echo "ERROR: openssl does not reference libcrypto.so.3"
        exit 1
    }


echo
echo "========================================"
echo " OpenSSL RPM buildroot validation PASS"
echo "========================================"
echo
echo "Executable:"
echo "  /opt/openssl35/bin/openssl"
echo
echo "Private libraries:"
echo "  /opt/openssl35/lib64/libssl.so.3"
echo "  /opt/openssl35/lib64/libcrypto.so.3"
echo
echo "RUNPATH:"
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
- Add relative $ORIGIN/../lib64 runtime library search path
- Validate RUNPATH during RPM build
- Remove tsget WWW::Curl::Easy dependency