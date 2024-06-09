#!/bin/bash

reserved=12582912
availableMemory=$((1024 * $( (grep MemAvailable /proc/meminfo || grep MemTotal /proc/meminfo) | sed 's/[^0-9]//g' ) ))
memoryLimit=$availableMemory
[ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ] && memoryLimit=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes | sed 's/[^0-9]//g')
[[ ! -z $memoryLimit && $memoryLimit -gt 0 && $memoryLimit -lt $availableMemory ]] && availableMemory=$memoryLimit
if [ $availableMemory -le $(($reserved * 2)) ]; then
    echo "Not enough memory" >&2
    exit 1
fi
availableMemory=$(($availableMemory - $reserved))
rr_cache_size=$(($availableMemory / 3))
# Use roughly twice as much rrset cache memory as msg cache memory
msg_cache_size=$(($rr_cache_size / 2))
nproc=$(nproc)
export nproc
if [ "$nproc" -gt 1 ]; then
    threads=$((nproc - 1))
    # Calculate base 2 log of the number of processors
    nproc_log=$(perl -e 'printf "%5.5f\n", log($ENV{nproc})/log(2);')

    # Round the logarithm to an integer
    rounded_nproc_log="$(printf '%.*f\n' 0 "$nproc_log")"

    # Set *-slabs to a power of 2 close to the num-threads value.
    # This reduces lock contention.
    slabs=$(( 2 ** rounded_nproc_log ))
else
    threads=1
    slabs=4
fi

if [ ! -f /opt/unbound/etc/unbound/unbound.conf ]; then
    sed \
        -e "s/@MSG_CACHE_SIZE@/${msg_cache_size}/" \
        -e "s/@RR_CACHE_SIZE@/${rr_cache_size}/" \
        -e "s/@THREADS@/${threads}/" \
        -e "s/@SLABS@/${slabs}/" \
        > /opt/unbound/etc/unbound/unbound.conf << EOT
# The server clause sets the main parameters.
server:
  username: ""
  chroot: ""
  logfile: "/data/dnslogs/unbound.log"
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
  so-rcvbuf: 3m
  so-sndbuf: 3m
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
   forward-addr: 127.0.0.1@5335

cachedb:
  backend: "redis"
  redis-server-host: 127.0.0.1
  redis-server-port: 6379
  redis-timeout: 100
EOT
fi

mkdir -p /opt/unbound/etc/unbound
sysctl -w net.core.rmem_max=4194304
sysctl -w net.core.wmem_max=4194304
exec /opt/unbound/sbin/unbound -d -c /opt/unbound/etc/unbound/unbound.conf
