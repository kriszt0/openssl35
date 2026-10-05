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

# build-rpm.sh normally supplies:
#   --define "build_jobs <N>"
# Fall back to one job if it was not supplied.
%{!?build_jobs:%global build_jobs 1}

%description
Isolated OpenSSL %{version} installation for Oracle Linux 7.

The package is installed under /opt/openssl35 and does not replace
the operating system OpenSSL package, binaries or libraries.

The OpenSSL executable uses the libssl and libcrypto shared libraries
shipped with this package under /opt/openssl35/lib64.

%prep
%setup -q -n openssl-%{version}


%build

# Make the installed OpenSSL executable resolve its own OpenSSL shared
# libraries relative to /opt/openssl35/bin.
#
# $ORIGIN is evaluated by the dynamic loader at runtime.
export LDFLAGS="-Wl,-rpath,\$ORIGIN/../lib64"

./Configure linux-x86_64 \
    --prefix=%{install_root} \
    --openssldir=%{install_root}/ssl \
    --libdir=lib64 \
    shared \
    zlib

make -j%{build_jobs}

# Full upstream OpenSSL test suite.
make test -j%{build_jobs}


%install

rm -rf %{buildroot}

make install_sw install_ssldirs DESTDIR=%{buildroot}

# These timestamp-query helper scripts introduce an unnecessary
# perl(WWW::Curl::Easy) runtime dependency.
rm -f %{buildroot}%{install_root}/ssl/misc/tsget
rm -f %{buildroot}%{install_root}/ssl/misc/tsget.pl


# ----------------------------------------------------------------------
# Build-time package validation
# ----------------------------------------------------------------------

# Main executable must exist.
test -x %{buildroot}%{install_root}/bin/openssl

# The package must contain its own OpenSSL 3 shared libraries.
test -f %{buildroot}%{install_root}/lib64/libssl.so.3
test -f %{buildroot}%{install_root}/lib64/libcrypto.so.3

# Verify that the executable contains the private runtime library path.
readelf -d %{buildroot}%{install_root}/bin/openssl | \
    grep -E 'RPATH|RUNPATH' | \
    grep -q '\$ORIGIN/../lib64'


%files

%license LICENSE.txt
%doc README.md

/opt/openssl35


%changelog
* Mon Oct 05 2026 Company Build Engineering <build@example.company> - 3.5.9-1
- Install OpenSSL under /opt/openssl35
- Keep OpenSSL isolated from the operating system OpenSSL
- Package private libssl.so.3 and libcrypto.so.3
- Add relative runtime library search path
- Remove tsget helpers and WWW::Curl::Easy dependency