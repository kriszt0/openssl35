%{!?openssl_version:%global openssl_version 3.5.9}
%{!?pkg_release:%global pkg_release 1}
%{!?ossl_prefix:%global ossl_prefix /opt/openssl35}

%global debug_package %{nil}

# A /opt alatti libssl.so.3 / libcrypto.so.3 ne szennyezze a rendszer Provides/Requires-át
%global __provides_exclude_from ^%{ossl_prefix}/.*$
%global __requires_exclude ^(libssl\.so\.3.*|libcrypto\.so\.3.*|perl.*)$

Name:           openssl35
Version:        %{openssl_version}
Release:        %{pkg_release}%{?dist}
Summary:        OpenSSL 3.5 LTS side-install (%{ossl_prefix})
License:        Apache-2.0
URL:            https://www.openssl.org/
Source0:        https://github.com/openssl/openssl/releases/download/openssl-%{version}/openssl-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  perl-core
BuildRequires:  perl-IPC-Cmd
Requires:       ca-certificates

%description
OpenSSL %{version}, a rendszer OpenSSL 1.0.2-től függetlenül telepítve a
%{ossl_prefix} alá. RPATH-os linkelés: nem kell LD_LIBRARY_PATH és ld.so.conf
módosítás, nincs scriptlet. A CA bundle a rendszer trust store-ra mutat.

%prep
%setup -q -n openssl-%{version}

%build
./Configure \
    --prefix=%{ossl_prefix} \
    --openssldir=%{ossl_prefix}/ssl \
    --libdir=lib64 \
    shared no-tests no-docs \
    -fstack-protector-strong -D_FORTIFY_SOURCE=2 \
    -Wl,-z,relro -Wl,-z,now \
    -Wl,-rpath,%{ossl_prefix}/lib64 -Wl,--enable-new-dtags
make %{?_smp_mflags}

%install
export QA_RPATHS=$(( 0x0001|0x0002|0x0010 ))
make DESTDIR=%{buildroot} install_sw install_ssldirs
rm -f %{buildroot}%{ossl_prefix}/lib64/*.a

# Rendszer CA trust store
rm -rf %{buildroot}%{ossl_prefix}/ssl/certs
ln -s /etc/pki/tls/certs     %{buildroot}%{ossl_prefix}/ssl/certs
ln -sf /etc/pki/tls/cert.pem %{buildroot}%{ossl_prefix}/ssl/cert.pem

%files
%defattr(-,root,root,-)
%license LICENSE.txt
%{ossl_prefix}

%changelog
* Thu Oct 01 2026 DevOps <devops@example.com> - %{openssl_version}-%{pkg_release}
- OpenSSL %{openssl_version} el7-re, prefix: %{ossl_prefix}
