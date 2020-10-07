#!/bin/bash
export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

branch="v3gun"
VERSION="2.1.0-dev"

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
      'i386' | 'i686')
        MACHINE='32'
        ;;
      'amd64' | 'x86_64')
        MACHINE='64'
        ;;
      'armv5tel')
        MACHINE='arm32-v5'
        ;;
      'armv6l')
        MACHINE='arm32-v6'
        ;;
      'armv7' | 'armv7l')
        MACHINE='arm32-v7a'
        ;;
      'armv8' | 'aarch64')
        MACHINE='arm64-v8a'
        ;;
      'mips')
        MACHINE='mips32'
        ;;
      'mipsle')
        MACHINE='mips32le'
        ;;
      'mips64')
        MACHINE='mips64'
        ;;
      'mips64le')
        MACHINE='mips64le'
        ;;
      'ppc64')
        MACHINE='ppc64'
        ;;
      'ppc64le')
        MACHINE='ppc64le'
        ;;
      'riscv64')
        MACHINE='riscv64'
        ;;
      's390x')
        MACHINE='s390x'
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

  if [[ "${realIP4}" == "${resolvedIP4}" ]] || [[ "${realIP4}" == "${resolvedIP6}" ]] || [[ "${realIP6}" == "${resolvedIP4}" ]] || [[ "${realIP6}" == "${resolvedIP6}" ]]; then
    return 0
  else
    return 1
  fi
}

show_links() {
  local uuid="$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[0].settings.clients[0].id')"
  local path="$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[2].streamSettings.wsSettings.path')"
  local sni="$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[0].tag')"
  local cf_node="$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[1].tag')"
  # path ss+ws: /[base], path vless+ws: /[base]ws, path vmess+ws: /[base]wss, path trojan+ws: /[base]tj

  colorEcho ${YELLOW} "===============分 享 链 接==============="

  echo "VLESS"
  printf "(TCP) %s:443 %s\n" "${sni}" "${uuid}"
  printf "(WSS) %s:443 %s %s\n" "${sni}" "${uuid}" "${path}ws"
  echo ""

  echo "VMess (新版分享格式)"
  local uri_vmess_cf="ws+tls:${uuid}@${cf_node}:443/?path=`urlEncode "${path}wss"`&host=${sni}&tlsAllowInsecure=false&tlsServerName=${sni}#`urlEncode "${sni} (WSS)"`"
  local uri_vmess_cf="ws+tls:${uuid}@${sni}:443/?path=`urlEncode "${path}wss"`&host=${sni}&tlsAllowInsecure=false&tlsServerName=${sni}#`urlEncode "${sni} (WSS)"`"
  printf "%s\n%s\n" "vmess://${uri_vmess_cf}" "vmess://${uri_vmess}"
  echo ""

  echo "VMess (旧版分享格式)"
  local json_vmess_cf="{\"add\":\"${cf_node}\",\"aid\":\"1\",\"host\":\"${sni}\",\"id\":\"${uuid}\",\"net\":\"ws\",\"path\":\"${path}wss\",\"port\":\"443\",\"ps\":\"${sni} (WSS)\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
  local uri_vmess_2dust_cf="$(printf %s "${json_vmess_cf}" | base64 --wrap=0)"
  local json_vmess="{\"add\":\"${sni}\",\"aid\":\"1\",\"host\":\"${sni}\",\"id\":\"${uuid}\",\"net\":\"ws\",\"path\":\"${path}wss\",\"port\":\"443\",\"ps\":\"${sni} (WSS)\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
  local uri_vmess_2dust="$(printf %s "${json_vmess}" | base64 --wrap=0)"
  printf "%s\n%s\n" "vmess://${uri_vmess_2dust_cf}" "vmess://${uri_vmess_2dust}"
  echo ""

  echo "Trojan"
  local uri_trojan="${uuid}@${sni}:443?peer=${sni}&sni=${sni}#`urlEncode "${sni} (Trojan)"`"
  printf "%s\n\n" "trojan://${uri_trojan}"
  echo ""

  echo "Trojan-Go"
  local uri_trojango="${uuid}@${sni}:443?&sni=${sni}&type=ws&host=${sni}&path=`urlEncode "${path}tj"`#`urlEncode "${sni} (Trojan-Go)"`"
  local uri_trojango_cf="${uuid}@${cf_node}:443?&sni=${sni}&type=ws&host=${sni}&path=`urlEncode "${path}tj"`#`urlEncode "${sni} (Trojan-Go)"`"
  printf "%s\n" "trojan-go://${uri_trojango_cf}" "trojan-go://${uri_trojango}"
  echo ""

  echo "Shadowsocks"
  local user_ss="$(printf %s "aes-128-gcm:${uuid}" | base64 --wrap=0)"
  local uri_ss="${user_ss}@${sni}:443/?plugin=`urlEncode "v2ray-plugin;tls;host=${sni};path=${path}"`#`urlEncode "${sni} (SS)"`"
  printf "%s\n" "ss://${uri_ss}"

  #colorEcho ${YELLOW} "===============配 置 文 件==============="
  #echo "VLESS"
  #printf "%s\n\n" "https://${sni}/`printf %s "${uuid_vless} | sed -e 's/-//g' | head -c 13"`/client.json"

  #echo "VMess"
  #printf "%s\n\n" "https://${sni}/`printf %s "${uuid_vmess} | sed -e 's/-//g' | head -c 13"`/client.json"

  #echo "Trojan"
  #printf "%s\n\n" "https://${sni}/`printf %s ${passwd_trojan} | head -c 9`/client.json"

  #echo "Trojan-Go"
  #printf "%s\n\n" "https://${sni}/`printf %s "${passwd_trojan}${path_trojan}" | head -c 13`/client.json"
  colorEcho ${YELLOW} "========================================"
}

gen_config_v2ray() {
  local sni="$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[0].tag')"
  local cf_node="$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[1].tag')"
  local uuid_vless="$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[0].settings.clients[0].id')"
  local uuid_vmess="$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[1].settings.clients[0].id')"
  local config_path_vless="$(printf %s ${uuid_vless} | sed -e 's/-//g' | head -c 13)"
  local config_path_vmess="$(printf %s ${uuid_vmess} | sed -e 's/-//g' | head -c 13)"

  if [ ! -d "/var/www/html/${config_path_vless}" ]; then
    ${sudoCmd} $(which mkdir) -p "/var/www/html/config_path_vless"
  fi

  if [ ! -d "/var/www/html/${config_path_vmess}" ]; then
    ${sudoCmd} $(which mkdir) -p "/var/www/html/config_path_vmess"
  fi

  ${sudoCmd} cat > "/var/www/html/${config_path_vless}/config.json" <<-EOF
{
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
          "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "${sni}",
            "port": 443,
            "users": [
                {
                  "id": "${uuid_vless}",
                  "flow": "xtls-rprx-origin",
                  "encryption": "none"
                }
            ]
          }
        ]
      }
    },
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
            "geoip:private"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": [
            "geoip:cn"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": [
            "geosite:cn"
        ],
        "outboundTag": "direct"
      }
    ]
  }
}
EOF

  ${sudoCmd} cat > "/var/www/html/${config_path_vmess}/config.json" <<-EOF
{
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
          "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "${sni}",
            "port": 443,
            "users": [
                {
                  "id": "${uuid_vmess}"
                }
            ]
          }
        ]
      }
    },
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
            "geoip:private"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": [
            "geoip:cn"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": [
            "geosite:cn"
        ],
        "outboundTag": "direct"
      }
    ]
  }
}
EOF
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
  ${sudoCmd} ${PACKAGE_MANAGEMENT_INSTALL} coreutils curl git wget unzip -y
  ${sudoCmd} ${PACKAGE_MANAGEMENT_INSTALL} jq -y
  ${sudoCmd} ${PACKAGE_MANAGEMENT_INSTALL} nginx -y

  # install jq mannualy if the package management didn't
  if [[ ! "$(commnad -v jq)" ]]; then
    echo "Fetching jq failed, trying manual installation"
    ${sudoCmd} curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/bin/jq
    ${sudoCmd} $(which chmod) +x /usr/bin/jq
  fi

  if [[ ! "$(commnad -v nginx)" ]]; then
    echo "Fetching nginx failed, trying building from source"
    cd $(mktemp -d)
    wget https://nginx.org/download/nginx-1.18.0.tar.gz
    tar -xvf nginx-1.18.0.tar.gz
    cd nginx-1.18.0.tar
    ${sudoCmd} ./configure
    ${sudoCmd} make
    ${sudoCmd} make install
    cd ~
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

set_v2ray_systemd() {
  ${sudoCmd} cat > "/usr/local/etc/v2ray/05_inbounds.json" <<-EOF
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
    local latest_version="$(curl -s "https://api.github.com/repos/v2fly/v2ray-core/release/latest" | jq '.tag_name' --raw-output)"
    echo "${latest_version}"
    local v2ray_link="https://github.com/v2fly/v2ray-core/releases/download/${latest_version}/v2ray-linux-${MACHINE}.zip"

    ${sudoCmd} $(which mkdir) -p "/usr/local/etc/v2ray"
    printf "Cretated: %s\n" "/usr/local/etc/v2ray"
    for BASE in 00_log 01_api 02_dns 03_routing 04_policy 05_inbounds 06_outbounds 07_transport 08_stats 09_reverse; do echo '{}' > "/usr/local/etc/v2ray/$BASE.json"; done
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
    local latest_version="$(curl -s "https://api.github.com/repos/v2fly/v2ray-core/release/latest" | jq '.tag_name' --raw-output)"
    echo "${latest_version}"
    local v2ray_link="https://github.com/v2fly/v2ray-core/releases/download/${latest_version}/v2ray-linux-${MACHINE}.zip"

    cd $(mktemp -d)
    wget -nv "${v2ray_link}" -O v2ray-core.zip
    unzip -q v2ray-core.zip && $(which rm) -rf v2ray-core.zip
    ${sudoCmd} $(which mv) v2ray /usr/local/bin/v2ray && ${sudoCmd} $(which chmod) +x /usr/local/bin/v2ray
    printf "Installed: %s\n" "/usr/local/bin/v2ray"
    ${sudoCmd} $(which mv) v2ctl /usr/local/bin/v2ctl && ${sudoCmd} $(which chmod) +x /usr/local/bin/v2ctl
    printf "Installed: %s\n" "/usr/local/bin/v2ctl"

    ${sudoCmd} systemctl daemon-reload
    colorEcho ${GREEN} "V2Ray ${latest_version} has been updated."
  fi
}

set_v2ray() {
  # $1: uuid for all (in trojan and ss uuid == passowrd)
  # $2: base path
  # $3: sni
  # $4: url of cf node
  # 3564: trojan, 3565: ss, 3566: vmess+wss, 3567: vless+wss, 3568: trojan+ws
  ${sudoCmd} cat > "/usr/local/etc/v2ray/05_inbounds.json" <<-EOF
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
            "path": "/$2",
            "dest": 3565,
            "xver": 1
          },
          {
            "path": "/$2ws",
            "dest": 3566,
            "xver": 1
          },
          {
            "path": "/$2wss",
            "dest": 3567,
            "xver": 1
          },
          {
            "path": "/$2tj",
            "dest": 3568
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
    },
    {
      "port": 3564,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$1"
          }
        ],
        "fallbacks": [
          {
            "dest": 80
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      },
      "tag": "$3"
    },
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
          "path": "/$2"
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
          "path": "/$2ws"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      }
    },
    {
      "port": 3567,
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
          "path": "/$2wss"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      }
    },
    {
      "port": 3568,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$1"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/$2tj"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      }
    }
  ]
}
EOF
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/03_routing.json -O /usr/local/etc/v2ray/03_routing.json
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/06_outbounds.json -O /usr/local/etc/v2ray/06_outbounds.json
}

set_redirect() {
  if [ -d "/etc/nginx/sites-available" ]; then # debian/ubuntu
    ${sudoCmd} cat > /etc/nginx/sites-available/default <<-EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://\$host\$request_uri;
}
EOF
  elif [ -d "/etc/nginx/conf.d" ];then # centos
    ${sudoCmd} cat > /etc/nginx/nginx.conf <<-EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        return 301 https://\$host\$request_uri;
    }
  }
EOF
  fi
}

set_nginx() {
  if [ -d "/etc/nginx/sites-available" ]; then # debian/ubuntu
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
  elif [ -d "/etc/nginx/conf.d" ];then # centos
    ${sudoCmd} cat > /etc/nginx/conf.d/v2gun.conf <<-EOF
server {
    listen 127.0.0.1:80;
    server_name $1;
    root /var/www/html;
    index index.php index.html index.htm;
}
EOF
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

    ${sudoCmd} $(which rm) -f /root/.acme.sh/$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[0].settings.tag')_ecc/$(read_json /usr/local/etc/v2ray/05_inbounds.json '.inbounds[0].settings.tag').key

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

    write_json /usr/local/etc/v2ray/05_inbounds.json ".inbounds[0].tag" "\"${V2_DOMAIN}\""
    write_json /etc/trojan-go/config.json ".websocket.host" "\"${V2_DOMAIN}\""

    ${sudoCmd} systemctl restart trojan-go

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

  # set crontab to auto update geoip.dat and geosite.dat
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/local/share/v2ray/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/local/share/v2ray/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -

  local uuid="$(cat '/proc/sys/kernel/random/uuid')"
  local path="/$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c $((10+$RANDOM%10)))"
  local cf_node="$(curl -s https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/custom/cf_node)"

  set_v2ray "${uuid}" "${path}" "${V2_DOMAIN}" "${cf_node}"

  ${sudoCmd} $(which mkdir) -p /etc/ssl/v2ray

  # temporary cert
  ${sudoCmd} openssl req -new -newkey rsa:2048 -days 1 -nodes -x509 -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=${V2_DOMAIN}" -keyout /etc/ssl/v2ray/key.pem -out /etc/ssl/v2ray/fullchain.pem
  ${sudoCmd} $(which chmod) 644 /etc/ssl/v2ray/key.pem
  ${sudoCmd} $(which chmod) 644 /etc/ssl/v2ray/fullchain.pem

  colorEcho ${BLUE} "Building dummy web site"
  build_web

  #colorEcho ${BLUE} "Generating client configs"
  #gen_config_v2ray
  #gen_config_trojan

  colorEcho ${BLUE} "Setting nginx"
  set_redirect
  set_nginx "${V2_DOMAIN}"

  # activate services
  colorEcho ${BLUE} "Activating services"
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  ${sudoCmd} systemctl enable nginx
  ${sudoCmd} systemctl restart nginx 2>/dev/null ## restart nginx to enable new config

  ${sudoCmd} systemctl enable v2ray
  ${sudoCmd} systemctl restart v2ray 2>/dev/null ## restart v2ray to enable new config

  get_acmesh
  get_cert "${V2_DOMAIN}"

  if [ -f "/root/.acme.sh/${V2_DOMAIN}_ecc/fullchain.cer" ]; then
    colorEcho ${GREEN} "安装 VLESS + VMess + Trojan 成功!"
    show_links
  else
    colorEcho ${RED} "证书签发失败, 请运行修复证书"
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
  echo "1) 安装 VLESS + VMess + Trojan-Go"
  echo "2) 修复证书 / 更换域名"
  echo "----------显示配置----------"
  echo "3) 显示链接"
  echo "----------组件管理----------"
  echo "4) 更新 v2ray-core"
  echo "----------实用工具----------"
  echo "5) VPS 工具箱 (含 BBR 脚本)"
  echo "----------卸载脚本----------"
  echo "6) 卸载脚本与全部组件"
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
      "3") show_links && continue_prompt ;;
      "4") get_v2ray && continue_prompt ;;
      "5") vps_tools ;;
      "6") rm_v2gun ;;
      *) break ;;
    esac
  done

}

identify_the_operating_system_and_architecture
menu