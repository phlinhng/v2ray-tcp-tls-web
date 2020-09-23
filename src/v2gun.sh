#!/bin/bash
export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

branch="v2gun"
VERSION="2.0 beta"

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
elif cat /etc/issue | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
fi

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
  local realIP="$(curl -s `curl -s https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/custom/ip_api`)"
  local resolvedIP4="$(ping $1 -c 1 | head -n 1 | grep  -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)"
  local resolvedIP6="$(ping $1 -c 1 | head -n 1 | grep  -oE '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))' | head -n 1)"

  if [[ "${realIP}" == "${resolvedIP4}" ]] || [[ "${realIP}" == "${resolvedIP6}" ]]; then
    return 0
  else
    return 1
  fi
}

show_links() {
  local sni="$(read_json /usr/local/etc/v2ray/config.json '.inbounds[0].settings.tag')"
  local cf_node="$(read_json /usr/local/etc/v2ray/config.json '.inbounds[1].settings.tag')"
  local uuid_vless="$(read_json /usr/local/etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
  local uuid_vmess="$(read_json /usr/local/etc/v2ray/config.json '.inbounds[1].settings.clients[0].id')"
  local path_vmess="$(read_json /usr/local/etc/v2ray/config.json '.inbounds[1].streamSettings.wsSettings.path')"
  local passwd_trojan="$(read_json /etc/trojan-go/config.json '.password[0]')"

  echo "VLESS"
  printf "%s:443 %s\n\n" "sni" "${uuid_vless}"

  echo "VMess (新版)"
  local uri_vmess="ws+tls:${uuid_vmeess}@{cf_node}:443/?path=${path_vmees}&host={sni}&tlsAllowInsecure=false&tlsServerName=${sni}#`urlEncode "${sni} (WSS)"`"
  printf "%s\n\n" "vmess://${uri_vmess}"

  echo "VMess (旧版)"
  local json_vmess="{\"add\":\"${cf_node}\",\"aid\":\"1\",\"host\":\"${sni}\",\"id\":\"${uuid_vmess}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${sni} (WSS)\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
  local uri_vmess_2dust="$(printf %s "${json_tcp}" | base64 --wrap=0)"
  printf "%s\n\n" "vmess://${uri_vmess_2dust}"

  echo "Trojan"
  local uri_trojan="${passwd_trojan}@${sni}:443?peer=${sni}&sni=${sni}#`urlEncode "${sni} (Trojan)"`"
  printf "%s\n" "trojan://${uri_trojan}"
}

preinstall() {
    # turning off selinux
    ${sudoCmd} setenforce 0
    ${sudoCmd} echo "SELINUX=disable" > /etc/selinux/config

    # turning off firewall
    ${sudoCmd} systemctl stop firewalld 2>/dev/null
    ${sudoCmd} systemctl disable firewalld 2>/dev/null

    # get dependencies
    ${sudoCmd} ${systemPackage} update -y
    ${sudoCmd} ${systemPackage} install software-properties-common -y -q # debian/ubuntu
    ${sudoCmd} add-apt-repository ppa:ondrej/nginx-mainline -y # debian/ubuntu
    ${sudoCmd} ${systemPackage} install epel-release -y # centos
    ${sudoCmd} ${systemPackage} update -y
    ${sudoCmd} ${systemPackage} install coreutil curl git jq nginx wget unzip -y
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

set_v2ray() {
  # $1: uuid for vless+tcp
  # $2: uuid for vmess+ws
  # $3: path for vmess+ws
  # $4: sni
  # $5: url of cf node
  for BASE in 00_log 01_api 02_dns 03_routing 04_policy 05_inbounds 06_outbounds 07_transport 08_stats 09_reverse; do echo '{}' > "/usr/local/etc/v2ray/$BASE.json"; done
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
      },
      "tag": "$4"
    },
    {
      "port": 3566,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$2",
            "alterId": 2
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
      },
      "tag": "$5"
    }
  ]
}
EOF
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/03_routing.json -O /usr/local/etc/v2ray/03_routing.json
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/06_outbounds.json -O /usr/local/etc/v2ray/06_outbounds.json
}

set_trojan() {
  ${sudoCmd} cat > "/etc/trojan-go/config.json" <<-EOF
{
  "run_type": "server",
  "local_addr": "127.0.0.1",
  "local_port": 8080,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "log_level": 3,
  "password": [
    "$1"
  ],
  "transport_plugin": {
    "enabled": true,
    "type": "plaintext"
  },
  "router": {
    "enabled": false
  }
}
EOF
}

set_redirect() {
  ${sudoCmd} cat > /etc/nginx/sites-available/default <<-EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://\$host\$request_uri;
}
EOF
}

set_nginx() {
  ${sudoCmd} rm /etc/nginx/sites-enabled/v2gun.conf
  ${sudoCmd} cat > /etc/nginx/sites-available/v2gun.conf <<-EOF
server {
listen 127.0.0.1:80;
    server_name $1;
    root /var/www/html;
    index index.php index.html index.htm;
}
EOF
  ${sudoCmd} cd /etc/nginx/sites-enabled
  ${sudoCmd} ln -s /etc/nginx/sites-available/v2gun.conf .
  ${sudoCmd} cd ~
}

install_v2ray() {
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

  preinstall

  # set time syncronise service
  ${sudoCmd} timedatectl set-ntp true

  get_v2ray
  build_v2ray

  get_trojan

  local uuid_vless="$(cat '/proc/sys/kernel/random/uuid')"
  local uuid_vmess="$(cat '/proc/sys/kernel/random/uuid')"
  local path_vmess="/$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 12)"
  local cf_node="$(curl -s https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/custom/ip_api)"
  local passwd_trojan="$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 12)"

  set_v2ray "${uuid_vless}" "${uuid_vmess}" "${path_vmess}" "${V2_DOMAIN}" "$(cf_node)"
  set_trojan "${passwd_trojan}"

  ${sudoCmd} mkdir -p /etc/ssl/v2ray

  # temporary config for issuing certs
  ${sudoCmd} cat > /etc/nginx/sites-enabled/v2gun.conf <<-EOF
server {
    listen 80;
    server_name ${V2_DOMAIN};
    root /var/www/html;
    index index.php index.html index.htm;
}
EOF

  get_cert "${V2_DOMAIN}"

  colorEcho ${BLUE} "Building dummy web site"
  build_web

  colorEcho ${BLUE} "Setting nginx"
  set_redirect
  set_nginx "${V2_DOMAIN}"

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

  colorEcho ${GREEN} "安装 VLESS (TLS) + VMess (WSS) + Trojan-Go 成功!"

  show_links
}

rm_v2gun() {
  curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/rm_v2gun.sh | bash
  exit 0
}

vps_tools() {
  wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/tools/vps_tools.sh -O /tmp/vps_tools.sh && chmod +x /tmp/vps_tools.sh && ${sudoCmd} /tmp/vps_tools.sh
  exit 0
}

show_menu() {
  echo ""
  echo "----------安装代理----------"
  echo "1) 安装 VLESS (TLS) + VMess (WSS) + Trojan-Go"
  echo "----------显示配置----------"
  echo "2) 显示链接"
  echo "----------组件管理----------"
  echo "3) 更新 v2ray-core"
  echo "4) 更新 trojan-go"
  echo "----------实用工具----------"
  echo "5) VPS 工具箱 (含 BBR 脚本)"
  echo "----------卸载脚本----------"
  echo "6) 卸载脚本与全部组件"
  echo ""
}

menu() {
  colorEcho ${YELLOW} "V2Ray & Trojan automated script v${VERSION}"
  colorEcho ${YELLOW} "author: phlinhng"
  echo ""

  #check_status

  COLUMNS=woof

  while true; do
    show_menu
    read -rp "选择操作 [输入任意值退出]: " opt
    case "${opt}" in
      "1") install_v2ray && continue_prompt ;;
      "2") show_links && continue_prompt ;;
      "3") get_v2ray && continue_prompt ;;
      "4") get_trojan && continue_prompt ;;
      "5") vps_tools ;;
      "6") rm_v2gun ;;
      *) break ;;
    esac
  done

}

menu