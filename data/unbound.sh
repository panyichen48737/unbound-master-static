#!/bin/bash

mkdir -p /opt/unbound/etc/unbound

if [ ! -f /opt/unbound/etc/unbound/unbound.conf ]; then
        /opt/unbound/etc/unbound/unbound.conf << EOT
# The server clause sets the main parameters.
server:
  username: ""
  chroot: ""
  logfile: "/opt/unbound/etc/unbound/unbound.log"
  log-queries: no
  log-servfail: yes
  log-time-ascii: yes
  use-syslog: no
  verbosity: 1
  interface: 0.0.0.0@5334	
  access-control: 0.0.0.0/0 allow
  do-not-query-localhost: no
  do-ip4: yes
  do-ip6: yes
  do-udp: yes
  do-tcp: yes
  do-daemonize: no
  num-threads: 2
  msg-cache-slabs: 4
  rrset-cache-slabs: 4
  key-cache-slabs: 4
  infra-cache-slabs: 4
  
  aggressive-nsec: yes
  hide-trustanchor: yes
  hide-version: yes
  hide-identity: yes
  qname-minimisation: yes
  qname-minimisation-strict: no
  minimal-responses: yes
  rrset-roundrobin: yes
  so-reuseport: yes
  infra-cache-numhosts: 10000
  unwanted-reply-threshold: 10000000
  so-rcvbuf: 4m
  so-sndbuf: 4m
  msg-cache-size: 64m
  key-cache-size: 64m
  neg-cache-size: 64m
  rrset-cache-size: 128m
  outgoing-range: 8192
  num-queries-per-thread: 4096
  outgoing-num-tcp: 1024
  incoming-num-tcp: 2048
  jostle-timeout: 300
  cache-min-ttl: 60
  cache-max-ttl: 3600
  cache-max-negative-ttl: 300
  infra-host-ttl: 3600
  serve-expired-ttl: 86400
  serve-expired-reply-ttl: 5
  serve-expired-client-timeout: 1800
  serve-expired: yes
  prefetch: yes
  prefetch-key: yes
  max-udp-size: 4096
  edns-buffer-size: 4096
  send-client-subnet: 0.0.0.0/0
  send-client-subnet: ::0/0
  max-client-subnet-ipv4: 24
  max-client-subnet-ipv6: 56
  client-subnet-always-forward: yes
  module-config: "subnetcache cachedb iterator"
  
  forward-zone:
   name: "."
   forward-addr: 172.16.0.5@5335

cachedb:
  backend: "redis"
  redis-server-host: 172.16.0.2
  redis-server-port: 6379
  redis-timeout: 100
EOT
fi


exec /opt/unbound/sbin/unbound -d -c /opt/unbound/etc/unbound/unbound.conf
