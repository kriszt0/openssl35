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

%global install_root /opt/openssl35

%description
Side-by-side OpenSSL %{version} installation. It deliberately does not replace
the operating system OpenSSL packages, binaries or libraries.

%prep
%setup -q -n openssl-%{version}

%build
./Configure linux-x86_64 \
    --prefix=%{install_root} \
    --openssldir=%{install_root}/ssl \
    shared zlib
make -j%{?_smp_build_ncpus:%{_smp_build_ncpus}} %{?_smp_mflags}
make test

%install
rm -rf %{buildroot}
make install_sw install_ssldirs DESTDIR=%{buildroot}

%post
/sbin/ldconfig || :

%postun
/sbin/ldconfig || :

%files
%license LICENSE.txt
%doc README.md
/opt/openssl35

%changelog
* Mon Oct 05 2026 Company Build Engineering <build@example.company> - 3.5.9-1
- Artifact factory package template
