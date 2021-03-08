# VLESS / Trojan-Go / Shadowsocks
automated script for xray-core and trojan-go

## Usage
```sh
curl -fsSL https://raw.staticdn.net/phlinhng/v2ray-tcp-tls-web/xray-dev/src/xwall.sh -o ~/xwall.sh && bash ~/xwall.sh
```
To run the script again once downloaded, just use the following command:
```
bash ~/xwall.sh
```

## Features
1. Higher offloading efficieny with xray-core frontend
2. Support Debian9+, Ubuntu 16+ and CentOS 7+ operation systems
3. Support both IPv4 and IPv6
4. BuyPass CA Certificates

## Architecture
+ VLESS over TCP with [XTLS](https://github.com/XTLS/Go) powered by [xray-core](https://github.com/XTLS/xray-core)
+ Trojan (protocol) and muxing powered by trojan-go (implementaion)
+ Trojan over WSS on Cloudflare powered by trojan-go and Cloudflare
+ Shadowsocks over WSS powered by [xray-core](https://github.com/XTLS/xray-core)
+ HTTP Website backend powered by nginx

## Supported Protocols
| Protocol | Transport | Mux | Direct | CDN | Qv2ray | Shadowrocket | Clash | v2rayN(G) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| VLESS | XTLS | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ |
| VLESS | TLS | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ |
| VLESS | WSS | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Trojan | TLS | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Trojan | WSS | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Shadowsocks | WSS | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

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
+ [@charlieethan/firewall-proxy](https://github.com/charlieethan/firewall-proxy)
+ [@XTLS/xray-core](https://github.com/XTLS/xray-core)

## Stargazers over time
[![Stargazers over time](https://starchart.cc/phlinhng/v2ray-tcp-tls-web.svg)](https://starchart.cc/phlinhng/v2ray-tcp-tls-web)
