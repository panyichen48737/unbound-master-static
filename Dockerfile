FROM debian:bookworm

WORKDIR /tmp/src

COPY / /

RUN build_deps="curl tar" && \
    set -x && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      $build_deps && \
    curl -O https://github.com/panyichen48737/unbound-master-static/releases/download/static/unbound-master-linux-x64.tar.gz && \
    tar -zxvf unbound-master-linux-x64.tar.gz
    mv unbound /opt
    mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/unbound.conf.example && \
    apt-get purge -y --auto-remove \
      $build_deps && \
    rm -rf \
        /opt/unbound/share/man \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*


COPY data/ /

RUN chmod +x /unbound.sh

WORKDIR /usr/local/unbound/

ENV PATH /usr/local/unbound/sbin:"$PATH"

EXPOSE 5334/tcp
EXPOSE 5334/udp

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 CMD drill @127.0.0.1@5334 baidu.com || exit 1

CMD ["/unbound.sh"]
