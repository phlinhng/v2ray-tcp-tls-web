# v2ray tcp+tls+web
automated script for v2Ray (TCP+TLS+Web)

## Usage
```
wget -N --no-check-certificate https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/v2.sh && chmod +x v2.sh && ./v2.sh
```

## [Tutorial in Chinese](https://github.com/phlinhng/v2ray-tcp-tls-web/wiki/v2Ray-TCP-TLS-WEB%E4%B8%80%E9%94%AE%E8%84%9A%E6%9C%AC-%E6%8C%87%E5%8D%97#%E5%AE%89%E8%A3%85tcptlsweb%E6%96%B0%E4%B8%89%E4%BB%B6%E5%A5%97)

## TCP+TLS vs WS+TLS
1. TCP+TLS has faster connection speed than WS+TLS benifit from that TCP is naturally faster than websocket
2. TCP+TLS has lower delay by saving 1-RTT from ws handshaking
3. TCP+TLS is not compatible with cloudflare free CDN plan as WSS does.

## Note
`tls-shunt-proxy` can proxify websocket traffic but it is not capable with CDN (and may not add support to this feature in forseeable future) so there is no benefit to use `tls-shunt-proxy` with ws. Please check [phlinhng/v2ray-caddy-cf](https://github.com/phlinhng/v2ray-caddy-cf) instead if you prefer to set v2Ray in WS+TLS+WEB mode.

# Related work
+ [phlinhng/v2ray-caddy-cf](https://github.com/phlinhng/v2ray-caddy-cf): automated script for v2Ray (WS+TLS+Web)
+ [Shawdowrockets 訂閱鏈接編輯器](https://www.phlinhng.com/b64-url-editor/): subscription manager

# Credit
+ [Project V](https://www.v2ray.com/)
+ [V2Ray 配置指南](https://toutyrater.github.io/)
+ [新 V2Ray 白话文指南](https://guide.v2fly.org/)
+ [templated.co/industrious](https://templated.co/industrious)
+ [@liberal-boy/tls-shunt-proxy](https://github.com/liberal-boy/tls-shunt-proxy)
+ [@atrandys/trojan](https://github.com/atrandys/trojan)
+ [@Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat)
+ [@mack-a/v2ray-agent](https://github.com/mack-a/v2ray-agent)
