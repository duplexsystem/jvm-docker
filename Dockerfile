ARG RHEL=9
ARG JAVA=jdk17
ARG ZING=$JAVA.0.0
ARG ZLIBNG=2.0.6

FROM registry.access.redhat.com/ubi$RHEL/ubi as builder
ARG RHEL
ARG ZLIBNG
ENV LANG='C.UTF-8' LANGUAGE='en_US:en' LC_ALL='C.UTF-8'
RUN dnf -y install make gcc tar; cd /; curl -LfsS https://dl.fedoraproject.org/pub/epel/epel-release-latest-$RHEL.noarch.rpm -o epel-release-latest-$RHEL.noarch.rpm; curl -LfsS https://github.com/zlib-ng/zlib-ng/archive/refs/tags/$ZLIBNG.tar.gz -o /zlib-ng-$ZLIBNG.tar.gz; tar -zxC / -f /zlib-ng-$ZLIBNG.tar.gz; cd /zlib-ng-$ZLIBNG; ./configure --zlib-compat; make -j$(nproc); make install; curl -LfsS https://repos.azul.com/zing/rhel/zing.repo -o /zing.repo

FROM registry.access.redhat.com/ubi$RHEL/ubi-minimal
ARG RHEL
ARG JAVA
ARG ZING
ENV LANG='C.UTF-8' LANGUAGE='en_US:en' LC_ALL='C.UTF-8'
COPY --from=builder /usr/local/lib/libz.* /usr/local/lib/
COPY --from=builder /zing.repo  /etc/yum.repos.d/
COPY --from=builder /epel-release-latest-$RHEL.noarch.rpm /

RUN rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-$RHEL; rpm --import https://repos.azul.com/azul-repo.key; rpm -v -i /epel-release-latest-$RHEL.noarch.rpm; microdnf update; microdnf -y install zing-$ZING mimalloc ca-certificates kernel-headers curl-minimal openssl git tar sqlite fontconfig freetype tzdata iproute libstdc++; rm -rf /epel-release-latest-$RHEL.noarch.rpm /opt/zing/zing-$JAVA/lib/src.zip /opt/zing/zing-$JAVA/bin/zvision /opt/zing/zing-$JAVA/demo /opt/zing/zing-$JAVA/man /opt/zing/zing-$JAVA/legal /opt/zing/zing-$JAVA/include /opt/zing/zing-$JAVA/lib/security/cacerts; ln -sT /etc/pki/ca-trust/extracted/java/cacerts /opt/zing/zing-$JAVA/lib/security/cacerts; microdnf clean all; rm -rf /var/cache/yum; useradd -d /home/container -m container

USER container
ENV LD_PRELOAD=/lib64/libmimalloc.so.2 \
    MIMALLOC_LARGE_OS_PAGES=1 \
    JAVA_HOME=/opt/zing/zing-$JAVA \
    USER=container \ 
    HOME=/home/container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]
