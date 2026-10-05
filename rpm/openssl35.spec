Name:           openssl35
Version:        %{openssl_version}
Release:        %{rpm_release}%{?dist}
Summary:        Company isolated OpenSSL 3.5.x distribution
License:        Apache-2.0
URL:            https://www.openssl.org/
Source0:        openssl-%{version}.tar.gz
BuildRequires:  gcc, make, perl, perl-core, zlib-devel
Requires:       zlib

%global install_base /opt/company/openssl
%global version_dir %{install_base}/%{version}

%description
Company-managed isolated OpenSSL build. It deliberately does not replace the Oracle Linux 7 system OpenSSL.

%prep
%setup -q -n openssl-%{version}

%build
./Configure linux-x86_64 --prefix=%{version_dir} --openssldir=%{version_dir}/ssl shared zlib
make -j%{?_smp_build_ncpus:%{_smp_build_ncpus}} %{?_smp_mflags}
make test

%install
rm -rf %{buildroot}
make install_sw DESTDIR=%{buildroot}
mkdir -p %{buildroot}%{install_base}
ln -sfn %{version} %{buildroot}%{install_base}/current

%post
ln -sfn %{version} %{install_base}/current

%files
%license LICENSE.txt
%doc README.md
%{version_dir}
%{install_base}/current

%changelog
* Mon Oct 05 2026 Build Engineering <build@example.invalid> - 3.5.9-1
- Production pipeline skeleton
