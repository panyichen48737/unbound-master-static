FROM debian:latest

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
    sysctl -w net.core.rmem_max=4194304 && \
    sysctl -w net.core.wmem_max=4194304 && \
    rm -rf \
        /opt/unbound/share/man \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*


COPY data/ /

RUN chmod +x /unbound.sh

WORKDIR /opt/unbound/

ENV PATH /opt/unbound/sbin:"$PATH"

EXPOSE 5334/tcp
EXPOSE 5334/udp

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 CMD drill @127.0.0.1@5334 baidu.com || exit 1

CMD ["/unbound.sh"]
