#!/bin/bash
export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

branch="v2gun"

# /usr/local/bin/v2script ##main
# /usr/local/bin/v2sub ##subscription manager
# /usr/local/etc/v2script/config.json ##config

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

# copied from v2ray official script
# colour code
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message
# colour function
colorEcho(){
  echo -e "\033[${1}${@:2}\033[0m" 1>& 2
}

red="\033[0;${RED}"
green="\033[0;${GREEN}"
nocolor="\033[0m"

#copied & modified from atrandys trojan scripts
#copy from 秋水逸冰 ss scripts
if [[ -f /etc/redhat-release ]]; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
elif cat /etc/issue | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
fi

VERSION="$(${sudoCmd} jq --raw-output '.version' /usr/local/etc/v2script/config.json 2>/dev/null | tr -d '\n')"

read_json() {
  # jq [key] [path-to-file]
  ${sudoCmd} jq --raw-output $2 $1 2>/dev/null | tr -d '\n'
} ## read_json [path-to-file] [key]

write_json() {
  # jq [key = value] [path-to-file]
  jq -r "$2 = $3" $1 > tmp.$$.json && ${sudoCmd} mv tmp.$$.json $1 && sleep 1
} ## write_json [path-to-file] [key = value]

urlEncode() {
  printf %s "$1" | jq -s -R -r @uri
}

urlDecode() {
  printf "${_//%/\\x}"
}

continue_prompt() {
  read -rp "继续其他操作 (yes/no)? " choice
  case "${choice}" in
    [yY]|[yY][eE][sS] ) return 0 ;;
    * ) exit 0;;
  esac
}

build_web() {
  if [ ! -f "/var/www/html/index.html" ]; then
    # choose and copy a random  template for dummy web pages
    local template="$(curl -s https://raw.githubusercontent.com/phlinhng/web-templates/master/list.txt | shuf -n  1)"
    wget -q https://raw.githubusercontent.com/phlinhng/web-templates/master/${template} -O /tmp/template.zip
    ${sudoCmd} mkdir -p /var/www/html
    ${sudoCmd} unzip -q /tmp/template.zip -d /var/www/html
    ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/custom/robots.txt -O /var/www/html/robots.txt
  else
    echo "Dummy website existed. Skip building."
  fi
}

checkIP() {
  local realIP="$(curl -s `curl -s https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/custom/ip_api`)"
  local resolvedIP="$(ping $1 -c 1 | head -n 1 | grep  -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)"

  if [[ "${realIP}" == "${resolvedIP}" ]]; then
    return 0
  else
    return 1
  fi
}

get_nginx() {
  if [[ systemPackage == "apt-get" ]]; then
    ${sudoCmd} ${systemPackage} install software-properties-common -y -q
    ${sudoCmd} add-apt-repository ppa:ondrej/nginx-mainline -y
    ${sudoCmd} ${systemPackage} install nginx-extras -y -q -f
  fi
}

get_cert() {
  colorEcho ${BLUE} "Installing acme.sh"
  curl -fsSL https://get.acme.sh | ${sudoCmd} bash

  colorEcho ${BLUE} "Issuing certificate"
  ${sudoCmd} /root/.acme.sh/acme.sh --issue --nginx -d "$1" --keylength ec-256

  # install certificate
  colorEcho ${BLUE} "Installing certificate"
  ${sudoCmd} /root/.acme.sh/acme.sh --install-cert --ecc -d "$1" \
  --key-file /etc/ssl/v2ray/key.pem --fullchain-file /etc/ssl/v2ray/fullchain.pem \
  --reloadcmd "chmod 644 /etc/ssl/v2ray/fullchain.pem; chmod 644 /etc/ssl/v2ray/key.pem; systemctl daemon-reload; systemctl restart v2ray"
}

get_v2ray() {
  curl -sL https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh | ${sudoCmd} bash
}

build_v2ray() {
  ${sudoCmd} cat > "/etc/systemd/system/v2ray.service" <<-EOF
[Unit]
Description=V2Ray Service
After=network.target nss-lookup.target
[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
Environment=V2RAY_LOCATION_ASSET=/usr/local/share/v2ray/
ExecStart=/usr/local/bin/v2ray -confdir /usr/local/etc/v2ray
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl enable v2ray
}

set_v2ray_with_trojan() {
  # $1: uuid for vless+tcp
  # $2: uuid for vmess+ws
  # $3: path for vmess+ws
  ${sudoCmd} cat > "/usr/local/etc/v2ray/05_inbounds.json" <<-EOF
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$1"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 8080
          },
          {
            "path": "$3",
            "dest": 3566,
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "alpn": [ "http/1.1" ],
          "certificates": [
            {
              "certificateFile": "/etc/ssl/v2ray/fullchain.pem",
              "keyFile": "/etc/ssl/v2ray/key.pem"
            }
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      }
    },
    {
      "port": 3566,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$2"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "$3"
        }
      }
    }
  ]
}
EOF
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/03_routing.json -O /usr/local/etc/v2ray/03_routing.json
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/06_outbounds.json -O /usr/local/etc/v2ray/06_outbounds.json
}

get_trojan() {
  if [ ! -d "/usr/bin/trojan-go" ]; then
    colorEcho ${BLUE} "trojan-go is not installed. start installation"

    colorEcho ${BLUE} "Getting the latest version of trojan-go"
    local latest_version="$(curl -s "https://api.github.com/repos/p4gefau1t/trojan-go/releases" | jq '.[0].tag_name' --raw-output)"
    echo "${latest_version}"
    local trojango_link="https://github.com/p4gefau1t/trojan-go/releases/download/${latest_version}/trojan-go-linux-amd64.zip"

    ${sudoCmd} mkdir -p "/etc/trojan-go"

    cd $(mktemp -d)
    wget -nv "${trojango_link}" -O trojan-go.zip
    unzip -q trojan-go.zip && rm -rf trojan-go.zip
    ${sudoCmd} mv trojan-go /usr/bin/trojan-go
    ${sudoCmd} mv geoip.dat -O /usr/bin/geoip.dat
    ${sudoCmd} mv geosite.dat -O /usr/bin/geosite.dat

    colorEcho ${BLUE} "Building trojan-go.service"
    ${sudoCmd} mv example/trojan-go.service /etc/systemd/system/trojan-go.service

    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl enable trojan-go

    colorEcho ${GREEN} "trojan-go is installed."
  else
    colorEcho ${BLUE} "Getting the latest version of trojan-go"
    local latest_version="$(curl -s "https://api.github.com/repos/p4gefau1t/trojan-go/releases" | jq '.[0].tag_name' --raw-output)"
    echo "${latest_version}"
    local trojango_link="https://github.com/p4gefau1t/trojan-go/releases/download/${latest_version}/trojan-go-linux-amd64.zip"

    cd $(mktemp -d)
    wget -nv "${trojango_link}" -O trojan-go.zip
    unzip trojan-go.zip
    ${sudoCmd} mv trojan-go /usr/bin/trojan-go
  fi
}

install_v2ray_and_trojan() {
  while true; do
    read -rp "解析到本 VPS 的域名: " V2_DOMAIN
    if checkIP "${V2_DOMAIN}"; then
      colorEcho ${GREEN} "域名 ${V2_DOMAIN} 解析正确, 即将开始安装"
      break
    else
      colorEcho ${RED} "域名 ${V2_DOMAIN} 解析有误 (yes: 强制继续, no: 重新输入, quit: 离开)"
      read -rp "若您确定域名解析正确, 可以继续进行安装作业. 强制继续? (yes/no/quit) " forceConfirm
      case "${forceConfirm}" in
        [yY]|[yY][eE][sS] ) break ;;
        [qQ]|[qQ][uU][iI][tT] ) return 0 ;;
      esac
    fi
  done
  write_json /usr/local/etc/v2gun.json ".sni" "\"${V2_DOMAIN}\""

  ${sudoCmd} ${systemPackage} update
  ${sudoCmd} ${systemPackage} install curl wget coreutils unzip -y -q

  # set time syncronise service
  ${sudoCmd} timedatectl set-ntp true

  get_nginx

  get_v2ray
  build_v2ray

  get_trojan

  set_v2ray_with_trojan

  ${sudoCmd} mkdir -p /etc/ssl/v2ray

  local uuid_vless="$(cat '/proc/sys/kernel/random/uuid')"
  local uuid_vmess="$(cat '/proc/sys/kernel/random/uuid')"
  local path_vmess_wss="/$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 12)"
  set_v2ray_with_trojan "${uuid_vless}" "${uuid_vmess}" "$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 12)"

  colorEcho ${BLUE} "Building dummy web site"
  build_web

  # activate services
  colorEcho ${BLUE} "Activating services"
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  ${sudoCmd} systemctl enable nginx
  ${sudoCmd} systemctl restart nginx 2>/dev/null

  ${sudoCmd} systemctl enable trojan-go
  ${sudoCmd} systemctl restart trojan-go ## restart tls-shunt-proxy to enable new config

  ${sudoCmd} systemctl enable v2ray
  ${sudoCmd} systemctl restart v2ray 2>/dev/null ## restart v2ray to enable new config

  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  colorEcho ${GREEN} "安装 TCP+TLS+WEB 成功!"
}

rm_v2gun() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/rm_v2gun.sh | bash
  exit 0
}

vps_tools() {
  ${sudoCmd} ${systemPackage} install wget -y -qq
  wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/vps_tools.sh -O /tmp/vps_tools.sh && chmod +x /tmp/vps_tools.sh && ${sudoCmd} /tmp/vps_tools.sh
  exit 0
}

show_menu() {
  echo ""
  echo "----------安装代理----------"
  echo "0) 安装 VLESS (TLS) + VMess (WSS) + Trojan-Go"
  #echo "1) 安装 VLESS (TLS) + VMess (WSS)"
  echo "----------显示配置----------"
  echo "2) 显示链接"
  echo "----------组件管理----------"
  echo "3) 更新 v2ray-core"
  echo "4) 更新 trojan-go"
  echo "----------实用工具----------"
  echo "5) VPS 工具箱 (含 BBR 脚本)"
  echo "----------卸载脚本----------"
  echo "11) 卸载脚本与全部组件"
  echo ""
}

menu() {
  colorEcho ${YELLOW} "V2Ray & Trojan automated script v${VERSION}"
  colorEcho ${YELLOW} "author: phlinhng"
  echo ""

  check_status

  COLUMNS=woof

  while true; do
    show_menu
    read -rp "选择操作 [输入任意值退出]: " opt
    case "${opt}" in
      "0") install_v2ray && continue_prompt ;;
      #"1") install_trojan && continue_prompt ;;
      "2") display_vmess && continue_prompt ;;
      "3") get_v2ray && continue_prompt ;;
      "4") get_trojan && continue_prompt ;;
      "5") vps_tools ;;
      "11") rm_v2script ;;
      *) break ;;
    esac
  done

}

menu
