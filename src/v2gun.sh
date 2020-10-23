#!/bin/bash
export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

branch="naive"
VERSION="2.2.0"

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

#copied & modified from v2fly fhs script
identify_the_operating_system_and_architecture() {
  if [[ "$(uname)" == 'Linux' ]]; then
    case "$(uname -m)" in
      'amd64' | 'x86_64')
        V2_MACHINE='64'
        TJ_MACHINE='amd64'
        NP_MACHINE='x64'
        CY_MACHINE='amd64'
        ;;
      'armv8' | 'aarch64')
        V2_MACHINE='arm64-v8a'
        TJ_MACHINE='armv8'
        NP_MACHINE='arm64'
        CY_MACHINE='arm64'
        ;;
    esac
    if [[ ! -f '/etc/os-release' ]]; then
      echo "error: Don't use outdated Linux distributions."
      exit 1
    fi
    if [[ -z "$(ls -l /sbin/init | grep systemd)" ]]; then
      echo "error: Only Linux distributions using systemd are supported."
      exit 1
    fi
    if [[ "$(command -v apt)" ]]; then
      PACKAGE_MANAGEMENT_UPDATE='apt update'
      PACKAGE_MANAGEMENT_INSTALL='apt install'
      PACKAGE_MANAGEMENT_REMOVE='apt remove'
    elif [[ "$(command -v yum)" ]]; then
      PACKAGE_MANAGEMENT_UPDATE='yum update'
      PACKAGE_MANAGEMENT_INSTALL='yum install'
      PACKAGE_MANAGEMENT_REMOVE='yum remove'
    elif [[ "$(command -v dnf)" ]]; then
      PACKAGE_MANAGEMENT_UPDATE='dnf update'
      PACKAGE_MANAGEMENT_INSTALL='dnf install'
      PACKAGE_MANAGEMENT_REMOVE='dnf remove'
    elif [[ "$(command -v zypper)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='zypper install'
      PACKAGE_MANAGEMENT_REMOVE='zypper remove'
    elif [[ "$(command -v pacman)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='pacman -S'
      PACKAGE_MANAGEMENT_REMOVE='pacman -R'
    else
      echo "error: The script does not support the package manager in this operating system."
      exit 1
    fi
  else
    echo "error: This operating system is not supported."
    exit 1
  fi
}

read_json() {
  # jq [key] [path-to-file]
  ${sudoCmd} jq --raw-output $2 $1 2>/dev/null | tr -d '\n'
} ## read_json [path-to-file] [key]

write_json() {
  # jq [key = value] [path-to-file]
  jq -r "$2 = $3" $1 > /tmp/tmp.$$.json && ${sudoCmd} mv /tmp/tmp.$$.json $1 && sleep 1
} ## write_json [path-to-file] [key] [value]

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
  local realIP4="$(curl -s `curl -s https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/custom/ip4_api`)"
  local realIP6="$(curl -s `curl -s https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/custom/ip6_api`)"
  local resolvedIP4="$(ping $1 -c 1 | head -n 1 | grep  -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)"
  local resolvedIP6="$(ping6 $1 -c 1 | head -n 1 | grep  -oE '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))' | head -n 1)"

  if [[ "${realIP4}" == "${resolvedIP4}" ]] || [[ "${realIP6}" == "${resolvedIP6}" ]]; then
    return 0
  else
    return 1
  fi
}

show_links() {
  if [ -f "/usr/local/bin/v2ray" ]; then
    local uuid="$(read_json /usr/local/etc/v2ray/05_inbounds_vless.json '.inbounds[0].settings.clients[0].id')"
    local path="$(read_json /usr/local/etc/v2ray/05_inbounds_ss.json '.inbounds[0].streamSettings.wsSettings.path')"
    local sni="$(read_json /usr/local/etc/v2ray/05_inbounds_vless.json '.inbounds[0].tag')"
    local cf_node="$(read_json /usr/local/etc/v2ray/05_inbounds_ss.json '.inbounds[0].tag')"
    # path ss+ws: /[base], path vless+ws: /[base]ws, path vmess+ws: /[base]wss, path trojan+ws: /[base]tj

    colorEcho ${YELLOW} "===============分 享 链 接==============="

    colorEcho ${BLUE} "VLESS"
    printf "(TCP) %s:443 %s\n" "${sni}" "${uuid}"
    printf "(WSS) %s:443 %s %s\n" "${sni}" "${uuid}" "${path}ws"
    echo ""

    colorEcho ${BLUE} "VMess (新版分享格式)"
    # https://github.com/v2ray/discussion/issues/720
    local uri_vmess_cf="ws+tls:${uuid}-1@${cf_node}:443/?path=`urlEncode "${path}wss"`&host=${sni}&tlsAllowInsecure=false&tlsServerName=${sni}#`urlEncode "${sni} (WSS)"`"
    local uri_vmess="ws+tls:${uuid}-1@${sni}:443/?path=`urlEncode "${path}wss"`&host=${sni}&tlsAllowInsecure=false&tlsServerName=${sni}#`urlEncode "${sni} (WSS)"`"
    printf "%s\n%s\n" "vmess://${uri_vmess_cf}" "vmess://${uri_vmess}"
    echo ""

    colorEcho ${BLUE} "VMess (旧版分享格式)"
    local json_vmess_cf="{\"add\":\"${cf_node}\",\"aid\":\"1\",\"host\":\"${sni}\",\"id\":\"${uuid}\",\"net\":\"ws\",\"path\":\"${path}wss\",\"port\":\"443\",\"ps\":\"${sni} (WSS)\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    local uri_vmess_2dust_cf="$(printf %s "${json_vmess_cf}" | base64 --wrap=0)"
    local json_vmess="{\"add\":\"${sni}\",\"aid\":\"1\",\"host\":\"${sni}\",\"id\":\"${uuid}\",\"net\":\"ws\",\"path\":\"${path}wss\",\"port\":\"443\",\"ps\":\"${sni} (WSS)\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    local uri_vmess_2dust="$(printf %s "${json_vmess}" | base64 --wrap=0)"
    printf "%s\n%s\n" "vmess://${uri_vmess_2dust_cf}" "vmess://${uri_vmess_2dust}"
    echo ""

    colorEcho ${BLUE} "Trojan"
    local uri_trojan="${uuid}@${sni}:443?peer=${sni}&sni=${sni}#`urlEncode "${sni} (Trojan)"`"
    printf "%s\n" "trojan://${uri_trojan}"
    echo ""

    colorEcho ${BLUE} "Trojan-Go"
    local uri_trojango="${uuid}@${sni}:443?sni=${sni}&type=ws&host=${sni}&path=`urlEncode "${path}tj"`#`urlEncode "${sni} (Trojan-Go)"`"
    local uri_trojango_cf="${uuid}@${cf_node}:443?sni=${sni}&type=ws&host=${sni}&path=`urlEncode "${path}tj"`#`urlEncode "${sni} (Trojan-Go)"`"
    printf "%s\n" "trojan-go://${uri_trojango_cf}" "trojan-go://${uri_trojango}"
    echo ""

    colorEcho ${BLUE} "Shadowsocks"
    local user_ss="$(printf %s "aes-128-gcm:${uuid}" | base64 --wrap=0)"
    local uri_ss="${user_ss}@${sni}:443/?plugin=`urlEncode "v2ray-plugin;tls;mode=websocket;host=${sni};path=${path};mux=0"`#`urlEncode "${sni} (SS)"`"
    printf "%s\n" "ss://${uri_ss}"

    colorEcho ${YELLOW} "========================================"
  fi
}

preinstall() {
  # turning off selinux
  ${sudoCmd} setenforce 0 2>/dev/null
  ${sudoCmd} echo "SELINUX=disable" > /etc/selinux/config

  # turning off firewall
  ${sudoCmd} systemctl stop firewalld 2>/dev/null
  ${sudoCmd} systemctl disable firewalld 2>/dev/null
  ${sudoCmd} ufw disable 2>/dev/null

  # get dependencies
  ${sudoCmd} ${PACKAGE_MANAGEMENT_INSTALL} epel-release -y 2>/dev/null # centos
  ${sudoCmd} ${PACKAGE_MANAGEMENT_UPDATE} -y
  ${sudoCmd} ${PACKAGE_MANAGEMENT_INSTALL} coreutils curl git wget unzip xz-utils -y

  ${sudoCmd} ${PACKAGE_MANAGEMENT_INSTALL} jq -y
  # install jq mannualy if the package management didn't
  if [[ ! "$(command -v jq)" ]]; then
    echo "Fetching jq failed, trying manual installation"
    ${sudoCmd} curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/bin/jq
    ${sudoCmd} $(which chmod) +x /usr/bin/jq
  fi
}

get_acmesh() {
  colorEcho ${BLUE} "Installing acme.sh"
  curl -fsSL https://get.acme.sh | ${sudoCmd} bash
}

get_cert() {
  colorEcho ${BLUE} "Issuing certificate"
  ${sudoCmd} /root/.acme.sh/acme.sh --issue --nginx -d "$1" --keylength ec-256

  # install certificate
  colorEcho ${BLUE} "Installing certificate"
  ${sudoCmd} /root/.acme.sh/acme.sh --install-cert --ecc -d "$1" \
  --key-file /etc/ssl/v2ray/key.pem --fullchain-file /etc/ssl/v2ray/fullchain.pem \
  --reloadcmd "chmod 644 /etc/ssl/v2ray/fullchain.pem; chmod 644 /etc/ssl/v2ray/key.pem; systemctl restart v2ray"
}

get_trojan() {
  if [ ! -d "/usr/bin/trojan-go" ]; then
    colorEcho ${BLUE} "trojan-go is not installed. start installation"

    colorEcho ${BLUE} "Getting the latest version of trojan-go"
    local latest_version="$(curl -s "https://api.github.com/repos/p4gefau1t/trojan-go/releases" | jq '.[0].tag_name' --raw-output)"
    echo "${latest_version}"
    local trojango_link="https://github.com/p4gefau1t/trojan-go/releases/download/${latest_version}/trojan-go-linux-${TJ_MACHINE}.zip"

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
    local trojango_link="https://github.com/p4gefau1t/trojan-go/releases/download/${latest_version}/trojan-go-linux-${V2_MACHINE}.zip"

    cd $(mktemp -d)
    wget -nv "${trojango_link}" -O trojan-go.zip
    unzip trojan-go.zip
    ${sudoCmd} mv trojan-go /usr/bin/trojan-go
  fi
}

set_v2ray_systemd() {
  ${sudoCmd} cat > "/etc/systemd/system/v2ray.service" <<-EOF
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
Environment=V2RAY_LOCATION_ASSET=/usr/local/share/v2ray/
ExecStart=/usr/local/bin/v2ray -confdir /usr/local/etc/v2ray
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
}

get_v2ray() {
  if [ ! -f "/usr/local/bin/v2ray" ]; then
    colorEcho ${BLUE} "V2Ray is not installed. start installation"

    colorEcho ${BLUE} "Getting the latest version of v2ray-core"
    local latest_version="$(curl -s "https://api.github.com/repos/v2fly/v2ray-core/releases/latest" | jq '.tag_name' --raw-output)"
    echo "${latest_version}"
    local v2ray_link="https://github.com/v2fly/v2ray-core/releases/download/${latest_version}/v2ray-linux-${V2_MACHINE}.zip"

    ${sudoCmd} $(which mkdir) -p "/usr/local/etc/v2ray"
    printf "Cretated: %s\n" "/usr/local/etc/v2ray"
    for BASE in 00_log 01_api 02_dns 03_routing 04_policy 06_outbounds 07_transport 08_stats 09_reverse; do echo '{}' > "/usr/local/etc/v2ray/$BASE.json"; done
    ${sudoCmd} $(which mkdir) -p "/usr/local/share/v2ray"
    printf "Cretated: %s\n" "/usr/local/share/v2ray"

    cd $(mktemp -d)
    wget -nv "${v2ray_link}" -O v2ray-core.zip
    unzip -q v2ray-core.zip && $(which rm) -rf v2ray-core.zip
    ${sudoCmd} $(which mv) v2ray /usr/local/bin/v2ray && ${sudoCmd} $(which chmod) +x /usr/local/bin/v2ray
    printf "Installed: %s\n" "/usr/local/bin/v2ray"
    ${sudoCmd} $(which mv) v2ctl /usr/local/bin/v2ctl && ${sudoCmd} $(which chmod) +x /usr/local/bin/v2ctl
    printf "Installed: %s\n" "/usr/local/bin/v2ctl"
    ${sudoCmd} $(which mv) geoip.dat /usr/local/share/v2ray/geoip.dat
    printf "Installed: %s\n" "/usr/local/share/v2ray/geoip.dat"
    ${sudoCmd} $(which mv) geosite.dat /usr/local/share/v2ray/geosite.dat
    printf "Installed: %s\n" "/usr/local/share/v2ray/geosite.dat"

    colorEcho ${BLUE} "Building v2ray.service"
    set_v2ray_systemd

    ${sudoCmd} systemctl daemon-reload

    colorEcho ${GREEN} "V2Ray ${latest_version} is installed."
  else
    colorEcho ${BLUE} "Getting the latest version of v2ray-core"
    local latest_version="$(curl -s "https://api.github.com/repos/v2fly/v2ray-core/releases/latest" | jq '.tag_name' --raw-output)"
    echo "${latest_version}"
    local v2ray_link="https://github.com/v2fly/v2ray-core/releases/download/${latest_version}/v2ray-linux-${V2_MACHINE}.zip"

    cd $(mktemp -d)
    wget -nv "${v2ray_link}" -O v2ray-core.zip
    unzip -q v2ray-core.zip && $(which rm) -rf v2ray-core.zip
    ${sudoCmd} $(which mv) v2ray /usr/local/bin/v2ray && ${sudoCmd} $(which chmod) +x /usr/local/bin/v2ray
    printf "Installed: %s\n" "/usr/local/bin/v2ray"
    ${sudoCmd} $(which mv) v2ctl /usr/local/bin/v2ctl && ${sudoCmd} $(which chmod) +x /usr/local/bin/v2ctl
    printf "Installed: %s\n" "/usr/local/bin/v2ctl"

    ${sudoCmd} systemctl restart v2ray
    colorEcho ${GREEN} "V2Ray ${latest_version} has been updated."
  fi
}

set_v2ray() {
  # $1: uuid for all except vless ws (in trojan and ss uuid == passowrd)
  # $2: base path
  # $3: sni
  # $4: url of cf node
  # 3564: trojan, 3565: ss, 3566: vmess+wss, 3567: vless+wss, 3568: trojan+ws
  ${sudoCmd} cat > "/usr/local/etc/v2ray/05_inbounds_vless.json" <<-EOF
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$1",
            "flow": "xtls-rprx-origin"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 3564
          },
          {
            "path": "$2tj",
            "dest": 3564
          },
          {
            "path": "$2",
            "dest": 3565,
            "xver": 1
          },
          {
            "path": "$2ws",
            "dest": 3566,
            "xver": 1
          },
          {
            "path": "$2wss",
            "dest": 3567,
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
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
      "tag": "$3"
    }
  ]
}
EOF
  ${sudoCmd} cat > "/usr/local/etc/v2ray/05_inbounds_ss.json" <<-EOF
{
  "inbounds": [
    {
      "port": 3565,
      "listen": "127.0.0.1",
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-128-gcm",
        "password": "$1",
        "network": "tcp"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "$2"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      },
      "tag": "$4"
    }
  ]
}
EOF
  ${sudoCmd} cat > "/usr/local/etc/v2ray/05_inbounds_vless_ws.json" <<-EOF
{
  "inbounds": [
    {
      "port": 3566,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$1"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "$2ws"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      },
      "tag": "vless_ws"
    }
  ]
}
EOF
  ${sudoCmd} cat > "/usr/local/etc/v2ray/05_inbounds_vmess_ws.json" <<-EOF
{
  "inbounds": [
    {
      "port": 3567,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$1",
            "alterId": 2
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "$2wss"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      },
      "tag": "vmess_ws"
    }
  ]
}
EOF
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/03_routing.json -O /usr/local/etc/v2ray/03_routing.json
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/06_outbounds.json -O /usr/local/etc/v2ray/06_outbounds.json
}

set_trojan() {
  # $1: password
  # $2: ws path
  # $3: sni
  ${sudoCmd} cat > "/etc/trojan-go/config.json" <<-EOF
{
  "run_type": "server",
  "local_addr": "127.0.0.1",
  "local_port": 3564,
  "remote_addr": "127.0.0.1",
  "remote_port": 8080,
  "log_level": 3,
  "password": [
    "$1"
  ],
  "transport_plugin": {
    "enabled": true,
    "type": "plaintext"
  },
  "websocket": {
    "enabled": true,
    "path": "$2",
    "host": "$3"
  },
  "router": {
    "enabled": false
  }
}
EOF
}

set_naive() {
  ${sudoCmd} cat > "/usr/local/etc/naive/config.json" <<-EOF
{
  "listen": "http://127.0.0.1:8080",
  "padding": "true"
}
EOF
}

set_naive_systemd() {
  ${sudoCmd} cat > "/etc/systemd/system/naive.service" <<-EOF
[Unit]
Description=NaïveProxy Service
Documentation=https://github.com/klzgrad/naiveproxy
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/naive /usr/local/etc/naive/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
}

get_naiveproxy() {
  if [ ! -f "/usr/local/bin/naive" ]; then
    colorEcho ${BLUE} "NaiveProxy is not installed. start installation"

    colorEcho ${BLUE} "Getting the latest version of naiveproxy"
    local latest_version="$(curl -s "https://api.github.com/repos/klzgrad/naiveproxy/releases/latest" | jq '.tag_name' --raw-output)"
    echo "${latest_version}"
    local naive_link="https://github.com/klzgrad/naiveproxy/releases/download/${latest_version}/naiveproxy-${latest_version}-linux-${V2_MACHINE}.tar.xz"

    ${sudoCmd} $(which mkdir) -p "/usr/local/etc/naive"
    set_naive
    printf "Cretated: %s\n" "/usr/local/etc/naive/config.json"

    cd $(mktemp -d)
    wget -nv "${naive_link}" -O naive.tar.xz
    tar Jxvf naive.tar.xz && $(which rm) -rf naive.tar.xz
    cd "naiveproxy-${latest_version}-linux-${V2_MACHINE}"
    ${sudoCmd} $(which mv) naive /usr/local/bin/naive && ${sudoCmd} $(which chmod) +x /usr/local/bin/naive
    printf "Installed: %s\n" "/usr/local/bin/naive"

    colorEcho ${BLUE} "Building naive.service"
    set_naive_systemd

    ${sudoCmd} systemctl daemon-reload

    colorEcho ${GREEN} "NaiveProxy ${latest_version} is installed."
  else
    colorEcho ${BLUE} "Getting the latest version of naiveproxy"
    local latest_version="$(curl -s "https://api.github.com/repos/klzgrad/naiveproxy/releases/latest" | jq '.tag_name' --raw-output)"
    echo "${latest_version}"
    local naive_link="https://github.com/klzgrad/naiveproxy/releases/download/${latest_version}/naiveproxy-${latest_version}-linux-${V2_MACHINE}.tar.xz"

    cd $(mktemp -d)
    wget -nv "${naive_link}" -O naive.tar.xz
    tar Jxvf naive.tar.xz && $(which rm) -rf naive.tar.xz
    cd "naiveproxy-${latest_version}-linux-${V2_MACHINE}"
    ${sudoCmd} $(which mv) naive /usr/local/bin/naive && ${sudoCmd} $(which chmod) +x /usr/local/bin/naive
    printf "Installed: %s\n" "/usr/local/bin/naive"

    ${sudoCmd} systemctl restart naive
    colorEcho ${GREEN} "NaiveProxy ${latest_version} has been updated."
  fi
}

set_caddy_systemd() {
  ${sudoCmd} cat > "/etc/systemd/system/caddy.service" <<-EOF
[Unit]
Description=Caddy - Fast, multi-platform web server with automatic HTTPS
Documentation=https://caddyserver.com/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/caddy/caddy start
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
}

set_caddy() {
  ${sudoCmd} cat > "/usr/local/bin/caddy/Caddyfile"<<-EOF
:80, $1{
  tls off
  route {
    redir https://$1{uri}
  }
}
:8080, $1{
  tls off
  route {
    forward_proxy {
      basic_auth $2 $3
      hide_ip
      hide_via
      probe_resistance { $1:443 }
    }
    file_server { root /var/www/html }
  }
}
EOF
}

get_caddy() {
  if [ ! -d "/usr/local/bin/caddy" ]; then
    colorEcho ${BLUE} "Caddy 2 is not installed. start installation"

    local caddy_link="https://github.com/charlieethan/build/releases/download/v2.2.1/caddy-linux-${CY_MACHINE}"

    ${sudoCmd} $(which mkdir) -p "/usr/local/bin/caddy"
    printf "Cretated: %s\n" "/usr/local/bin/caddy"

    ${sudoCmd} wget -nv "${caddy_link}" -O /usr/local/bin/caddy/caddy && chmod +x /usr/local/bin/caddy/caddy
    printf "Installed: %s\n" "/usr/local/bin/caddy/caddy"

    colorEcho ${BLUE} "Building caddy.service"
    set_caddy_systemd

    ${sudoCmd} systemctl daemon-reload

    colorEcho ${GREEN} "Caddy 2 is installed."
  fi
}



fix_cert() {
  if [ -f "/usr/local/bin/v2ray" ]; then
    while true; do
      read -rp "解析到本 VPS 的域名: " V2_DOMAIN
      if checkIP "${V2_DOMAIN}"; then
        colorEcho ${GREEN} "域名 ${V2_DOMAIN} 解析正确, 即将开始修复证书"
        break
      else
        colorEcho ${RED} "域名 ${V2_DOMAIN} 解析有误 (yes: 强制继续, no: 重新输入, quit: 离开)"
        read -rp "若您确定域名解析正确, 可以继续进行修复作业. 强制继续? (yes/no/quit) " forceConfirm
        case "${forceConfirm}" in
          [yY]|[yY][eE][sS] ) break ;;
          [qQ]|[qQ][uU][iI][tT] ) return 0 ;;
        esac
      fi
    done

    ${sudoCmd} $(which rm) -f /root/.acme.sh/$(read_json /usr/local/etc/v2ray/05_inbounds_vless.json '.inbounds[0].tag')_ecc/$(read_json /usr/local/etc/v2ray/05_inbounds_vless.json '.inbounds[0].tag').key

    colorEcho ${BLUE} "Re-setting nginx"
    set_nginx "${V2_DOMAIN}"
    ${sudoCmd} systemctl restart nginx 2>/dev/null

    colorEcho ${BLUE} "Re-setting v2ray"
    # temporary cert
    ${sudoCmd} openssl req -new -newkey rsa:2048 -days 1 -nodes -x509 -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=${V2_DOMAIN}" -keyout /etc/ssl/v2ray/key.pem -out /etc/ssl/v2ray/fullchain.pem
    ${sudoCmd} chmod 644 /etc/ssl/v2ray/key.pem
    ${sudoCmd} chmod 644 /etc/ssl/v2ray/fullchain.pem

    ${sudoCmd} systemctl restart v2ray 2>/dev/null

    colorEcho ${BLUE} "Re-issuing certificates for ${V2_DOMAIN}"
    get_cert "${V2_DOMAIN}"

    write_json /usr/local/etc/v2ray/05_inbounds_vless.json ".inbounds[0].tag" "\"${V2_DOMAIN}\""

    if [ -f "/root/.acme.sh/${V2_DOMAIN}_ecc/fullchain.cer" ]; then
      colorEcho ${GREEN} "证书修复成功!"
      show_links
    else
      colorEcho ${RED} "证书签发失败, 請运行修复证书"
    fi
  else
    colorEcho ${YELLOW} "请先安装 V2Ray"
  fi
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
  get_trojan
  get_naiveproxy
  get_caddy

  # set crontab to auto update geoip.dat and geosite.dat
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/local/share/v2ray/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/local/share/v2ray/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -

  local uuid="$(cat '/proc/sys/kernel/random/uuid')"
  local path="/$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c $((10+$RANDOM%10)))"
  local cf_node="$(curl -s https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/custom/cf_node)"

  colorEcho ${BLUE} "Setting v2ray"
  set_v2ray "${uuid}" "${path}" "${V2_DOMAIN}" "${cf_node}"
  colorEcho ${BLUE} "Setting trojan"
  set_trojan "${uuid}" "${path}tj" "${V2_DOMAIN}"
  colorEcho ${BLUE} "Setting caddy"
  set_caddy "${V2_DOMAIN}" "user@${V2_DOMAIN}" "${uuid}"

  ${sudoCmd} $(which mkdir) -p /etc/ssl/v2ray

  # temporary cert
  ${sudoCmd} openssl req -new -newkey rsa:2048 -days 1 -nodes -x509 -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=${V2_DOMAIN}" -keyout /etc/ssl/v2ray/key.pem -out /etc/ssl/v2ray/fullchain.pem
  ${sudoCmd} $(which chmod) 644 /etc/ssl/v2ray/key.pem
  ${sudoCmd} $(which chmod) 644 /etc/ssl/v2ray/fullchain.pem

  colorEcho ${BLUE} "Building dummy web site"
  build_web

  # activate services
  colorEcho ${BLUE} "Activating services"
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  ${sudoCmd} systemctl enable caddy
  ${sudoCmd} systemctl restart caddy 2>/dev/null ## restart v2ray to enable new config

  ${sudoCmd} systemctl enable trojan-go
  ${sudoCmd} systemctl restart trojan-go 2>/dev/null

  ${sudoCmd} systemctl enable v2ray
  ${sudoCmd} systemctl restart v2ray 2>/dev/null ## restart v2ray to enable new config

  ${sudoCmd} systemctl enable naive
  ${sudoCmd} systemctl restart naive 2>/dev/null

  sleep 5

  get_acmesh
  get_cert "${V2_DOMAIN}"

  if [ -f "/root/.acme.sh/${V2_DOMAIN}_ecc/fullchain.cer" ]; then
    colorEcho ${GREEN} "安装 VLESS + VMess + Trojan + NaiveProxy 成功!"
    show_links
  else
    colorEcho ${RED} "证书签发失败, 请运行修复证书"
  fi
}

edit_cf_node() {
  if [ -f "/usr/local/bin/v2ray" ]; then
  local cf_node_current="$(read_json /usr/local/etc/v2ray/05_inbounds_ss.json '.inbounds[0].tag')"
  printf "%s\n" "输入编号使用建议值"
  printf "1. %s\n" "icook.hk"
  printf "2. %s\n" "www.digitalocean.com"
  printf "3. %s\n" "www.garmin.com"
  printf "4. %s\n" "amp.cloudflare.com"
  read -p "输入新的 CF 节点地址 [留空则使用现有值 ${cf_node_current}]: " cf_node_new
  case "${cf_node_new}" in
    "1") cf_node_new="icook.hk" ;;
    "2") cf_node_new="www.digitalocean.com" ;;
    "3") cf_node_new="www.garmin.com" ;;
    "4") cf_node_new="amp.cloudflare.com" ;;
  esac
  if [ -z "${cf_node_new}" ]; then
    cf_node_new="${cf_node_current}"
  fi
  write_json /usr/local/etc/v2ray/05_inbounds_ss.json ".inbounds[0].tag" "\"${cf_node_new}\""
  sleep 1
  printf "%s\n" "CF 节点己变更为 ${cf_node_new}"
  show_links
  fi
}

vps_tools() {
  ${sudoCmd} ${PACKAGE_MANAGEMENT_INSTALL} wget -y
  wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/tools/vps_tools.sh -O /tmp/vps_tools.sh && bash /tmp/vps_tools.sh
  exit 0
}

rm_v2gun() {
  if [ -f "/usr/local/bin/v2ray" ]; then
    wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/rm_v2gun.sh -O /tmp/rm_v2gun.sh && bash /tmp/rm_v2gun.sh
    exit 0
  fi
}

show_menu() {
  echo ""
  echo "----------安装代理----------"
  echo "1) 安装 VLESS + VMess + Trojan + NaiveProxy"
  echo "2) 修复证书 / 更换域名"
  echo "3) 自定义 Cloudflare 节点"
  echo "----------显示配置----------"
  echo "4) 显示链接"
  echo "----------组件管理----------"
  echo "5) 更新 v2ray-core"
  echo "6) 更新 trojan-go"
  echo "7) 更新 naiveproxy"
  echo "----------实用工具----------"
  echo "8) VPS 工具箱 (含 BBR 脚本)"
  echo "----------卸载脚本----------"
  echo "9) 卸载脚本与全部组件"
  echo ""
}

menu() {
  colorEcho ${YELLOW} "V2Ray & Trojan automated script v${VERSION}"
  colorEcho ${YELLOW} "author: phlinhng"

  #check_status

  COLUMNS=woof

  while true; do
    show_menu
    read -rp "选择操作 [输入任意值退出]: " opt
    case "${opt}" in
      "1") install_v2ray && continue_prompt ;;
      "2") fix_cert && continue_prompt ;;
      "3") edit_cf_node && continue_prompt ;;
      "4") show_links && continue_prompt ;;
      "5") get_v2ray && continue_prompt ;;
      "6") vps_tools ;;
      "7") rm_v2gun ;;
      *) break ;;
    esac
  done

}

identify_the_operating_system_and_architecture
menu
