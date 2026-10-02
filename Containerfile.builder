# El7 ABI build környezet. Production: a BASE_IMAGE-t digestre pineld (@sha256:...),
# és az image-et a CI futtató cache-eli (Containerfile hash a tag).
ARG BASE_IMAGE=docker.io/library/oraclelinux:7
FROM ${BASE_IMAGE}

# tsflags=noscripts: el7 rpm scriptlet-spin workaround (lásd a repo README-jét); eldobható build image.
RUN yum -y install --setopt=tsflags=noscripts --setopt=timeout=60 \
        gcc make perl perl-core perl-IPC-Cmd \
        rpm-build rpm-sign gnupg2 redhat-rpm-config \
        tar gzip findutils which \
 && yum clean all && rm -rf /var/cache/yum \
 && mkdir -p /root/rpmbuild/BUILD /root/rpmbuild/RPMS /root/rpmbuild/SOURCES \
             /root/rpmbuild/SPECS /root/rpmbuild/SRPMS

WORKDIR /root/rpmbuild
