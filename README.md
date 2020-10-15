# VLESS / VMess / Trojan-Go
automated script for VLESS, VMess and Trojan-Go

## Usage
```sh
curl -fsSL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/vless/src/v2gun.sh -o ~/v2gun.sh && bash ~/v2gun.sh
```
To run the script again once downloaded, just use the following command:
```
bash ~/v2gun.sh
```

## Features
1. VLESS / VMess / Trojan-Go all in one
2. Higher offloading efficieny with v2ray-core as frontend
3. Support Debian9+, Ubuntu 16+ and CentOS 7+ operation systems
4. Support both IPv4 and IPv6

## Architecture
+ VLESS over TCP with [XTLS](https://github.com/XTLS/Go) powered by v2ray-core
+ VMess over WSS on Cloudflare powered by v2ray-core and Cloudflare
+ Trojan (protocol) and muxing powered by v2ray-core (implementaion)
+ Trojan over WSS on Cloudflare powered by v2ray-core and Cloudflare
+ HTTP Website backend powered by nginx

## Supported Protocols
| Protocol | Transport | Mux | Direct | CDN | Qv2ray | Shadowrocket | Clash | v2rayN(G) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| VLESS | XTLS | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ |
| VLESS | TLS | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ |
| VLESS | WSS | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| VMess | WSS | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Trojan | TLS | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Trojan | WSS | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Shadowsocks | WSS | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

12 protocols combinations with 19 connection methods in total.

## Related work
+ [Shawdowrockets 訂閱鏈接編輯器](https://www.phlinhng.com/b64-url-editor): subscription manager
+ [v2script](https://github.com/phlinhng/v2ray-tcp-tls-web/tree/master): v1.x version

## Telegram
https://t.me/technologyshare

## Credit
+ [Project V](https://www.v2fly.org/)
+ [V2Ray 配置指南](https://toutyrater.github.io/)
+ [新 V2Ray 白话文指南](https://guide.v2fly.org/)
+ [templated.co](https://templated.co)
+ [@liberal-boy/tls-shunt-proxy](https://github.com/liberal-boy/tls-shunt-proxy)
+ [@atrandys/trojan](https://github.com/atrandys/trojan)
+ [@Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat)
+ [@mack-a/v2ray-agent](https://github.com/mack-a/v2ray-agent)
+ [@chiakge/Linux-NetSpeed](https://github.com/chiakge/Linux-NetSpeed)
+ [@ylx2016/Linux-NetSpeed](https://github.com/ylx2016/Linux-NetSpeed)
+ [@LemonBench/LemonBench](https://github.com/LemonBench/LemonBench)
+ [@tindy2013/subconverter](https://github.com/tindy2013/subconverter)
+ [@p4gefau1t/trojan-go](https://github.com/p4gefau1t/trojan-go)
+ [@rprx/v2ray-vless](https://github.com/rprx/v2ray-vless)
+ [@acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh)
+ [@nginx/nginx](https://github.com/nginx/nginx)

## Stargazers over time
[![Stargazers over time](https://starchart.cc/phlinhng/v2ray-tcp-tls-web.svg)](https://starchart.cc/phlinhng/v2ray-tcp-tls-web)
