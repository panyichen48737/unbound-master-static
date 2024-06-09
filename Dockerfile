FROM ubuntu:latest

WORKDIR /tmp/src

COPY / /

RUN build_deps="curl wget unzip gcc libc-dev libevent-dev libexpat1-dev libnghttp2-dev make cmake build-essential ca-certificates curl dirmngr gnupg libidn2-0-dev libssl-dev clang flex bison" && \
    set -x && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      $build_deps \
      bsdmainutils \
      ca-certificates \
      ldnsutils \
      libevent-2.1-7 \
      libexpat1 \
      libprotobuf-c-dev \
      protobuf-c-compiler && \
    echo "/usr/local/unbound" | bash /unbound_static_build.sh && \
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
