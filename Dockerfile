FROM ubuntu:latest

WORKDIR /tmp/src

RUN build_deps="wget" && \
    set -x && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      $build_deps && \
    wget https://github.com/panyichen48737/unbound-master-static/releases/download/static/unbound-master-linux-x64.tar.gz --no-check-certificate&& \
    tar -zxvf unbound-master-linux-x64.tar.gz && \
    mv unbound /opt && \
    mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/unbound.conf.example && \
    apt-get purge -y --auto-remove \
      $build_deps && \
    rm -rf \
        /opt/unbound/share/man \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*

COPY data/ /

RUN chmod +x /run.sh

WORKDIR /opt/unbound/

ENV PATH=/opt/unbound/sbin:"$PATH"

EXPOSE 5334/tcp
EXPOSE 5334/udp

CMD ["/run.sh"]
