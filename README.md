# V2RAY TCP+TLS+WEB / WSS+CDN and Trojan-go
automated script for V2Ray (TCP+TLS+Web), V2Ray (WSS+CDN), and Trojan-go

## Usage
```sh
bash <(curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/install.sh) && v2script
```
The above command will download the script, save it to `/usr/local/bin/v2script`, make it excutable and start it. To run the script again once installed, just use the following command:
```
v2script
```

## Screenshot
<img src="https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/image/v2script_menu.jpeg" alt="alt text" width="640">

## TCP+TLS vs WS+TLS
1. TCP+TLS has faster connection speed than WS+TLS benifit from that TCP is naturally faster than websocket
2. TCP+TLS has lower delay by saving 1-RTT from ws handshaking
3. TCP+TLS is not compatible with cloudflare free CDN plan as WSS does

## For Chinese users
1. 中文文档在[本项目 wiki 页面](https://github.com/phlinhng/v2ray-tcp-tls-web/wiki)
2. 任何情况下都**不需要**点亮 Cloudflare 云朵，否则 TCP+TLS 无法发挥作用（云朵是灰色的情况下还是能接入 CDN 的，相信我） 

## Related work
+ [@phlinhng/v2ray-caddy-cf](https://github.com/phlinhng/v2ray-caddy-cf): automated script for v2Ray (WS+TLS+Web)
+ [Shawdowrockets 訂閱鏈接編輯器](https://www.phlinhng.com/b64-url-editor): subscription manager

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
+ [@9seconds/mtg](https://github.com/9seconds/mtg)
+ [@p4gefau1t/trojan-go](https://github.com/p4gefau1t/trojan-go)

## Stargazers over time
[![Stargazers over time](https://starchart.cc/phlinhng/v2ray-tcp-tls-web.svg)](https://starchart.cc/phlinhng/v2ray-tcp-tls-web)
