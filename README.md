# v2ray tcp+tls+web
automated script for v2Ray (TCP+TLS+Web)

# Usage
```
wget -N --no-check-certificate https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/v2.sh && chmod +x v2.sh && ./v2.sh
```

# TCP+TLS vs WS+TLS
1. TCP+TLS has faster connection speed than WS+TLS benifit from that TCP is naturally faster than websocket
2. TCP+TLS has lower delay by saving 1-RTT from ws handshaking
3. TCP+TLS is not capable with cloudflare free CDN plan as WSS does.

# Note
`tls-shunt-proxy` can proxify websocket traffic but it is not capable with CDN (and may not add support to this feature in forseeable future) so there is no benefit to use `tls-shunt-proxy` with ws. Please check [phlinhng/v2ray-caddy-cf](https://github.com/phlinhng/v2ray-caddy-cf) instead if you prefer to set v2Ray in WS+TLS+WEB mode.

# Credit
+ [Project V](https://www.v2ray.com/)
+ [TLS 分流器](https://github.com/liberal-boy/tls-shunt-proxy)
+ [templated.co/industrious](https://templated.co/industrious)
+ [atrandys/trojan](https://github.com/atrandys/trojan)
