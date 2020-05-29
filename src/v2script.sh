#!/bin/bash
export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

branch="beta"

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

# a trick to redisplay menu option
show_menu() {
  echo ""
  colorEcho ${BLUE} "----------安装代理----------"
  echo "0) 安装 V2Ray TCP+TLS+WEB"
  echo "1) 安装 trojan-go"
  colorEcho ${BLUE} "----------显示配置----------"
  echo "2) 显示链接"
  echo "3) 管理订阅"
  colorEcho ${BLUE} "----------各种工具----------"
  echo "4) 设置 CDN"
  echo "5) 设置电报代理"
  echo "6) VPS 工具"
  colorEcho ${BLUE} "----------组件管理----------"
  echo "7) 更新 v2ray-core"
  echo "8) 更新 tls-shunt-proxy"
  echo "9) 更新 trojan-go"
  echo "10) 卸载脚本"
}

continue_prompt() {
  read -p "继续其他操作 (yes/no)? " choice
  case "${choice}" in
    y|Y|[yY][eE][sS] ) show_menu ;;
    * ) exit 0;;
  esac
}

display_vmess() {
  if [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]]; then
    printf '%s\n' "$(read_json /usr/local/etc/v2script/config.json '.sub.nodesList.tcp')"
  fi

  if [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare')" == "true" ]]; then
    printf '%s\n' "$(read_json /usr/local/etc/v2script/config.json '.sub.nodesList.wss')"
  fi

  if [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    printf '%s\n' "$(read_json /usr/local/etc/v2script/config.json '.sub.nodesList.trojan')"
  fi
}

display_link_main() {
  local V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"
  local TJ_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.trojan.tlsHeader')"
  if [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    printf '%s\n' "https://${V2_DOMAIN}/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')"
    printf '%s\n' "二维码: https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=sub://$(printf %s 'https://${V2_DOMAIN}/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')' | base64 --wrap=0)"
    printf '%s\n' "https://${TJ_DOMAIN}/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')"
    printf '%s\n' "二维码: https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=sub://$(printf %s 'https://${TJ_DOMAIN}/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')' | base64 --wrap=0)"
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]]; then
    printf '%s\n' "https://${V2_DOMAIN}/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')"
    printf '%s\n' "二维码: https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=sub://$(printf %s 'https://${V2_DOMAIN}/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')' | base64 --wrap=0)"
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    printf '%s\n' "https://${TJ_DOMAIN}/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')"
    printf '%s\n' "二维码: https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=sub://$(printf %s 'https://${TJ_DOMAIN}/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')' | base64 --wrap=0)"
  fi
}

sync_nodes() {
  local v2_remark=$1
  local tj_remark=$2

  local V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"
  local TJ_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.trojan.tlsHeader')"

  if [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]]; then
    local uuid_tcp="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
    local json_tcp="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid_tcp}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${v2_remark}\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    local uri_tcp="$(printf %s "${json_tcp}" | base64 --wrap=0)"
    write_json /usr/local/etc/v2script/config.json '.sub.nodesList.tcp' "$(printf %s "\"vmess://${uri_tcp}\"")"
  fi

  if [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare')" == "true" ]]; then
    local cfUrl="amp.cloudflare.com"
    local wssPath="$(read_json /etc/v2ray/config.json '.inbounds[1].streamSettings.wsSettings.path' | tr -d '/')"
    local uuid_wss="$(read_json /etc/v2ray/config.json '.inbounds[1].settings.clients[0].id')"
    local json_wss="{\"add\":\"${cfUrl}\",\"aid\":\"0\",\"host\":\"${V2_DOMAIN}\",\"id\":\"${uuid_wss}\",\"net\":\"ws\",\"path\":\"/${wssPath}\",\"port\":\"443\",\"ps\":\"${v2_remark} (CDN)\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    local uri_wss="$(printf %s "${json_wss}" | base64 --wrap=0)"
    write_json /usr/local/etc/v2script/config.json '.sub.nodesList.wss' "$(printf %s "\"vmess://${uri_wss}\"")"
  fi

  if [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    local uuid_torjan="$(read_json /etc/trojan-go/config.json '.password[0]')"
    local uri_torjan="${TJ_DOMAIN}@:443?peer=#$(urlEncode '${tj_remark}')"
    write_json /usr/local/etc/v2script/config.json '.sub.nodesList.trojan' "$(printf %s "\"trojan://{uri_torjan}\"")"
  fi

  if [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    local sub="$(printf '%s\n%s\n%s' "vmess://${uri_tcp}" "vmess://${uri_wss}"  "trojan://{uri_torjan}" | base64 --wrap=0)"
    printf %s "${sub}" | ${sudoCmd} tee /var/www/html/$(read_json /usr/local/etc/v2script/config.json '.sub.uri') >/dev/null
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare')" == "true" ]]; then
    local sub="$(printf '%s\n%s' "vmess://${uri_tcp}" "vmess://${uri_wss}" | base64 --wrap=0)"
    printf %s "${sub}" | ${sudoCmd} tee /var/www/html/$(read_json /usr/local/etc/v2script/config.json '.sub.uri') >/dev/null
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    local sub="$(printf '%s\n%s' "vmess://${uri_tcp}" "trojan://{uri_torjan}" | base64 --wrap=0)"
    printf %s "${sub}" | ${sudoCmd} tee /var/www/html/$(read_json /usr/local/etc/v2script/config.json '.sub.uri') >/dev/null
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]]; then
    local sub="$(printf '%s' "vmess://${uri_tcp}" | base64 --wrap=0)"
    printf %s "${sub}" | ${sudoCmd} tee /var/www/html/$(read_json /usr/local/etc/v2script/config.json '.sub.uri') >/dev/null
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    local sub="$(printf '%s' "trojan://{uri_torjan}" | base64 --wrap=0)"
    printf %s "${sub}" | ${sudoCmd} tee /var/www/html/$(read_json /usr/local/etc/v2script/config.json '.sub.uri') >/dev/null
  fi

  display_link_main
}

generate_link() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.enabled') != "true" ]]; then
    write_json /usr/local/etc/v2script/config.json '.sub.enabled' "true"
  fi

  if [[ "$(read_json /usr/local/etc/v2script/config.json '.sub.uri')" != "" ]]; then
    ${sudoCmd} rm -f /var/www/html/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')
    local randomName="$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 16)" #random file name for subscription
    write_json /usr/local/etc/v2script/config.json '.sub.uri' "\"${randomName}\""
  fi

  local V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"
  local TJ_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.trojan.tlsHeader')"

  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
    read -p "输入 V2Ray 节点名称 [留空则使用默认值]: " v2_remark
    if [ -z "${v2_remark}" ]; then
      v2_remark="${V2_DOMAIN}"
    fi
  else
    v2_remark="null"
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
    read -p "输入 Trojan 节点名称 [留空则使用默认值]: " tj_remark
    if [ -z "${tj_remark}" ]; then
      tj_remark="${TJ_DOMAIN}"
    fi
  else
    tj_remark="null"
  fi

  sync_nodes "${v2_remark}" "${tj_remark}"
  colorEcho ${GREEN} "己生成订阅"
}

update_link() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.enabled') == "true" ]]; then
    if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
      local v2_currentRemark="$(read_json /usr/local/etc/v2script/config.json '.sub.nodesList.tcp' | sed 's/^vmess:\/\///g' | base64 -d | jq --raw-output '.ps' | tr -d '\n')"
      read -p "输入 V2Ray 节点名称 [留空则使用现有值 ${v2_currentRemark}]: " v2_remark
      if [ -z "${v2_remark}" ]; then
        v2_remark="${v2_currentRemark}"
      fi
    else
      v2_remark="null"
    fi

    if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
      local tj_currentRemark="$(read_json /usr/local/etc/v2script/config.json '.sub.nodesList.trojan' | urlDecode)"
      read -p "输入 Trojan 节点名称[留空则使用默认值]: " tj_remark
      if [ -z "${tj_remark}" ]; then
        tj_remark="${tj_currentRemark}"
      fi
    else
      tj_remark="null"
    fi

    sync_nodes "${v2_remark}" "${tj_remark}"

    colorEcho ${GREEN} "己更新订阅"
  else
    generate_link
  fi
}

subscription_prompt() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.enabled') != "true" ]]; then
    read -p "生成订阅链接 (yes/no)? " linkConfirm
    case "${linkConfirm}" in
      y|Y|[yY][eE][sS] ) generate_link ;;
      * ) return 0 ;;
    esac
  else
    update_link
  fi
}

get_docker() {
  if [ ! -x "$(command -v docker)" ]; then
    curl -sL https://get.docker.com/ | ${sudoCmd} bash
    # install docker-compose
    #${sudoCmd} curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    #${sudoCmd} chmod +x /usr/local/bin/docker-compose
  fi
}

set_docker() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.installed') == "true" ]]; then
    if [ ! "$(${sudoCmd} docker ps -q --filter ancestor=nineseconds/mtg)" ]; then
      ${sudoCmd} docker rm $(${sudoCmd} docker stop $(${sudoCmd} docker ps -q --filter ancestor=nineseconds/mtg) 2>/dev/null) 2>/dev/null
      # start mtproto ## reference https://raw.githubusercontent.com/9seconds/mtg/master/run.sh
      ${sudoCmd} docker run -d --restart=always --name mtg --ulimit nofile=51200:51200 -p 127.0.0.1:3128:3128 nineseconds/mtg:latest run "$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
    fi
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.api.installed') == "true" ]]; then
    if [ ! "$(${sudoCmd} docker ps -q --filter ancestor=tindy2013/subconverter)" ]; then
      ${sudoCmd} docker rm $(${sudoCmd} docker stop $(${sudoCmd} docker ps -q --filter ancestor=tindy2013/subconverter) 2>/dev/null) 2>/dev/null
      ${sudoCmd} docker run -d --restart=always -p 127.0.0.1:25500:25500 -v /usr/local/etc/v2script/pref.ini:/base/pref.ini tindy2013/subconverter:latest
    fi
  fi
}

get_proxy() {
  if [ ! -f "/usr/local/bin/tls-shunt-proxy" ]; then
    colorEcho ${BLUE} "tls-shunt-proxy is not installed. start installation"
    curl -sL https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/dist/install.sh | ${sudoCmd} bash
    colorEcho ${GREEN} "tls-shunt-proxy is installed."
  else
    local API_URL="https://api.github.com/repos/liberal-boy/tls-shunt-proxy/releases/latest"
    local DOWNLOAD_URL="$(curl "${PROXY}" -H "Accept: application/json" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" -s "${API_URL}" --connect-timeout 10| grep 'browser_download_url' | cut -d\" -f4)"
    ${sudoCmd} curl -L -H "Cache-Control: no-cache" -o "/tmp/tls-shunt-proxy.zip" "${DOWNLOAD_URL}"
    ${sudoCmd} unzip -o -d /usr/local/bin/ "/tmp/tls-shunt-proxy.zip"
    ${sudoCmd} chmod +x /usr/local/bin/tls-shunt-proxy
  fi
}

set_proxy() {
  ${sudoCmd} /bin/cp /etc/tls-shunt-proxy/config.yaml /etc/tls-shunt-proxy/config.yaml.bak 2>/dev/null
  wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/tls-shunt-proxy.yaml -O /tmp/config_new.yaml

  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
    sed -i "s/FAKEV2DOMAIN/$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')/g" /tmp/config_new.yaml
    sed -i "s/##V2RAY@//g" /tmp/config_new.yaml
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare') == "true" ]]; then
    sed -i "s/FAKECDNPATH/$(read_json /etc/v2ray/config.json '.inbounds[1].streamSettings.wsSettings.path' | tr -d '/')/g" /tmp/config_new.yaml
    sed -i "s/##CDN@//g" /tmp/config_new.yaml
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.trojan.installed') == "true" ]]; then
    sed -i "s/FAKETJDOMAIN/$(read_json /usr/local/etc/v2script/config.json '.trojan.tlsHeader')/g" /tmp/config_new.yaml
    sed -i "s/##TROJAN@//g" /tmp/config_new.yaml
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.api.installed') == "true" ]]; then
    sed -i "s/FAKEAPIDOMAIN/$(read_json /usr/local/etc/v2script/config.json '.sub.api.tlsHeader')/g" /tmp/config_new.yaml
    sed -i "s/##SUBAPI@//g" /tmp/config_new.yaml
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.installed') == "true" ]]; then
    sed -i "s/FAKEMTDOMAIN/$(read_json /usr/local/etc/v2script/config.json '.mtproto.fakeTlsHeader')/g" /tmp/config_new.yaml
    sed -i "s/##MTPROTO@//g" /tmp/config_new.yaml
  fi

  ${sudoCmd} /bin/cp -f /tmp/config_new.yaml /etc/tls-shunt-proxy/config.yaml
}

get_caddy() {
  if [ ! -f "/usr/local/bin/caddy" ]; then
    #${sudoCmd} ${systemPackage} install libcap2-bin -y -qq

    curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/getcaddy.sh | ${sudoCmd} bash -s personal
    # Give the caddy binary the ability to bind to privileged ports (e.g. 80, 443) as a non-root user
    #${sudoCmd} setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

    # create user for caddy
    ${sudoCmd} useradd -d /usr/local/etc/caddy -M -s $(${sudoCmd} which nologin) -r -u 33 www-data
    ${sudoCmd} mkdir -p /usr/local/etc/caddy && ${sudoCmd} chown -R root:root /usr/local/etc/caddy
    ${sudoCmd} mkdir -p /usr/local/etc/ssl/caddy && ${sudoCmd} chown -R root:www-data /usr/local/etc/ssl/caddy
    ${sudoCmd} chmod 0770 /usr/local/etc/ssl/caddy

    wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/caddy.service -O /tmp/caddy.service
    ${sudoCmd} mv /tmp/caddy.service /etc/systemd/system/caddy.service
    ${sudoCmd} chown root:root /etc/systemd/system/caddy.service
    ${sudoCmd} chmod 644 /etc/systemd/system/caddy.service
  fi
}

set_caddy() {
  local caddyserver_file=$(mktemp)

  if [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    cat >> ${caddyserver_file} <<-EOF
$(read_json /usr/local/etc/v2script/config.json 'v2ray.tlsHeader'):80 {
    redir https://$(read_json /usr/local/etc/v2script/config.json 'v2ray.tlsHeader'){uri}
}
EOF
    echo "" >> ${caddyserver_file}
    cat >> ${caddyserver_file} <<-EOF
$(read_json /usr/local/etc/v2script/config.json 'trojan.tlsHeader'):80 {
    redir https://$(read_json /usr/local/etc/v2script/config.json 'trojan.tlsHeader'){uri}
}
EOF
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]]; then
    cat >> ${caddyserver_file} <<-EOF
$(read_json /usr/local/etc/v2script/config.json 'v2ray.tlsHeader'):80 {
    redir https://$(read_json /usr/local/etc/v2script/config.json 'v2ray.tlsHeader'){uri}
}
EOF
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    cat >> ${caddyserver_file} <<-EOF
$(read_json /usr/local/etc/v2script/config.json 'trojan.tlsHeader'):80 {
    redir https://$(read_json /usr/local/etc/v2script/config.json 'trojan.tlsHeader'){uri}
}
EOF
  fi

  ${sudoCmd} /bin/cp -f ${caddyserver_file} /usr/local/etc/caddy
}

build_web() {
  if [ ! -f "/var/www/html/index.html"]; then
    # choose and copy a random  template for dummy web pages
    local template="$(curl -s https://raw.githubusercontent.com/phlinhng/web-templates/master/list.txt | shuf -n  1)"
    wget -q https://raw.githubusercontent.com/phlinhng/web-templates/master/${template} -O /tmp/template.zip
    ${sudoCmd} mkdir -p /var/www/html
    ${sudoCmd} unzip -q /tmp/template.zip -d /var/www/html
    ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/custom/robots.txt -O /var/www/html/robots.txt
  fi
}

set_v2ray_wss() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare') != "true" ]]; then
    local uuid_wss="$(cat '/proc/sys/kernel/random/uuid')"
    local wssPath="$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 12)"
    local sni="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"
    local wssInbound="{\"protocol\": \"vmess\",
  \"port\": 3566,
  \"settings\": {
    \"clients\": [{
      \"id\": \"${uuid_wss}\",
      \"alterId\": 0
      }]
    },
  \"streamSettings\": {
      \"network\": \"ws\",
      \"wsSettings\": {
        \"path\": \"/${wssPath}\"
      }
    },
    \"sniffing\": {
      \"enabled\": true,
      \"destOverride\": [ \"http\", \"tls\" ]
    }
  }"

    # setting v2ray
    ${sudoCmd} /bin/cp /etc/v2ray/config.json /etc/v2ray/config.json.bak 2>/dev/null
    jq -r ".inbounds += [${wssInbound}]" /etc/v2ray/config.json  > tmp.$$.json && ${sudoCmd} mv tmp.$$.json /etc/v2ray/config.json
    write_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare' "true"

    set_proxy

    ${sudoCmd} systemctl restart v2ray 2>/dev/null
    ${sudoCmd} systemctl restart tls-shunt-proxy 2>/dev/null
    ${sudoCmd} systemctl daemon-reload

    colorEcho ${GREEN} "设置CDN成功!"
    local uuid_wss="$(read_json /etc/v2ray/config.json '.inbounds[1].settings.clients[0].id')"
    local cfUrl="amp.cloudflare.com"
    local currentRemark="$(read_json /usr/local/etc/v2script/config.json '.sub.nodesList.tcp' | sed 's/^vmess:\/\///g' | base64 -d | jq --raw-output '.ps' | tr -d '\n')"
    local json_wss="{\"add\":\"${cfUrl}\",\"aid\":\"0\",\"host\":\"${sni}\",\"id\":\"${uuid_wss}\",\"net\":\"ws\",\"path\":\"/${wssPath}\",\"port\":\"443\",\"ps\":\"${currentRemark} (CDN)\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    local uri_wss="$(printf %s "${json_wss}" | base64 --wrap=0)"

    echo "${cfUrl}:443"
    echo "${uuid_wss} (aid: 0)"
    echo "Header: ${sni}, Path: /${wssPath}" && echo ""
    echo "vmess://${uri_wss}" | tr -d '\n' && printf "\n"

    subscription_prompt
  else
    display_vmess
  fi
}

set_v2ray_wss_prompt() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
    if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare') != "true" ]]; then
      echo "此选项会增加一个WS+TLS+CDN的连接入口做为备用连接方式"
      echo "备用连接方式的速度、延迟可能不如TCP+TLS"
      colorEcho ${YELLOW} "请确保域名己解析到 Cloudflare 并设置成 \"DNS Only\" (云朵为灰色)"
      colorEcho ${YELLOW} "请确保域名己解析到 Cloudflare 并设置成 \"DNS Only\" (云朵为灰色)"
      colorEcho ${YELLOW} "请确保域名己解析到 Cloudflare 并设置成 \"DNS Only\" (云朵为灰色)"
      read -p "确定设置CDN (yes/no)? " wssConfirm
      case "${wssConfirm}" in
        y|Y|[yY][eE][sS] ) set_v2ray_wss ;;
        * ) return 0 ;;
      esac
    else
      display_vmess
    fi
  else
    colorEcho ${YELLOW} "请先安装TCP+TLS+WEB!"
    return 1
  fi
}

get_v2ray() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://install.direct/go.sh | ${sudoCmd} bash
}

build_v2ray() {
  if [ ! -d "/usr/bin/v2ray" ]; then
    get_v2ray
    colorEcho ${BLUE} "Building v2ray.service for domainsocket"
    local ds_service=$(mktemp)
    cat > ${ds_service} <<-EOF
[Unit]
Description=V2Ray - A unified platform for anti-censorship
Documentation=https://v2ray.com https://guide.v2fly.org
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
# If the version of systemd is 240 or above, then uncommenting Type=exec and commenting out Type=simple
#Type=exec
Type=simple
# Runs as root or add CAP_NET_BIND_SERVICE ability can bind 1 to 1024 port.
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=v2ray and commenting out User=root, the service will run as user v2ray.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
#User=root
User=v2ray
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=yes

ExecStartPre=$(which mkdir) -p /tmp/v2ray-ds
ExecStartPre=$(which rm) -rf /tmp/v2ray-ds/*.sock

ExecStart=/usr/bin/v2ray/v2ray -config /etc/v2ray/config.json

ExecStartPost=$(which sleep) 1
ExecStartPost=$(which chmod) 666 /tmp/v2ray-ds/v2ray.sock

Restart=on-failure
#Restart=always
#RestartSec=10
# Don't restart in the case of configuration error
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    # add new user and overwrite v2ray.service
    # https://github.com/v2ray/v2ray-core/issues/1011
    ${sudoCmd} useradd -d /etc/v2ray/ -M -s $(${sudoCmd} which nologin) v2ray
    ${sudoCmd} mv ${ds_service} /etc/systemd/system/v2ray.service
    ${sudoCmd} chown -R v2ray:v2ray /var/log/v2ray
    write_json /usr/local/etc/v2script/config.json ".v2ray.installed" "true"
    ${sudoCmd} timedatectl set-ntp true

    # set crontab to auto update geoip.dat and geosite.dat
    (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/bin/v2ray/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
    (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/bin/v2ray/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
  fi
}

install_v2ray() {
  read -p "解析到本 VPS 的域名: " V2_DOMAIN
  if [[ $(read_json /usr/local/etc/v2script/config.json '.trojan.installed') == "true" ]]; then
    if [[ $(read_json /usr/local/etc/v2script/config.json '.trojan.tlsHeader') == "${V2_DOMAIN}" ]] || [[ $(read_json /usr/local/etc/v2script/config.json '.sub.api.tlsHeader') == "${V2_DOMAIN}" ]]; then
      colorEcho ${RED} "域名 ${V2_DOMAIN} 与现有域名重复,  请使用别的域名"
      show_menu
      return 1
    fi
  fi
  write_json /usr/local/etc/v2script/config.json ".v2ray.tlsHeader" "\"${V2_DOMAIN}\""

  # install v2ray-core
  build_v2ray

  # install tls-shunt-proxy
  get_proxy

  # install caddy
  ${sudoCmd} docker rm $(${sudoCmd} docker stop $(${sudoCmd} docker ps -q --filter ancestor=abiosoft/caddy) 2>/dev/null) 2>/dev/null
  get_caddy

  # prevent some bug
  ${sudoCmd} rm -rf /var/www/html
  ${sudoCmd} rm -rf /usr/local/etc/ssl/caddy/*
  ${sudoCmd} rm -f /usr/local/etc/Caddyfile # path for old version v2script

  # create config files
  if [[ $(read_json /etc/v2ray/config.json '.inbounds[0].streamSettings.network') != "domainsocket" ]]; then
    colorEcho ${BLUE} "Setting v2Ray"
    wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/v2ray.json -O /tmp/v2ray.json
    sed -i "s/FAKEPORT/$(read_json /etc/v2ray/config.json '.inbounds[0].port')/g" /tmp/v2ray.json
    sed -i "s/FAKEUUID/$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')/g" /tmp/v2ray.json
    ${sudoCmd} /bin/cp -f /tmp/v2ray.json /etc/v2ray/config.json
  fi

  colorEcho ${BLUE} "Setting tls-shunt-proxy"
  set_proxy

  colorEcho ${BLUE} "Setting caddy"
  set_caddy

  colorEcho ${BLUE} "Building dummy web site"
  build_web

  # kill process occupying port 80
  ${sudoCmd} kill -9 $(lsof -t -i:80) 2>/dev/null

  # activate services
  colorEcho ${BLUE} "Activating services"
  ${sudoCmd} systemctl enable v2ray
  ${sudoCmd} systemctl restart v2ray 2>/dev/null ## restart v2ray to enable new config
  ${sudoCmd} systemctl enable tls-shunt-proxy
  ${sudoCmd} systemctl restart tls-shunt-proxy ## restart tls-shunt-proxy to enable new config
  ${sudoCmd} systemctl enable caddy
  ${sudoCmd} systemctl restart caddy
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  colorEcho ${GREEN} "安装 TCP+TLS+WEB 成功!"

  local V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"
  local uuid_tcp="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
  local json_tcp="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid_tcp}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${V2_DOMAIN}\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
  local uri_tcp="$(printf %s "${json_tcp}" | base64 --wrap=0)"
  write_json /usr/local/etc/v2script/config.json '.sub.nodesList.tcp' "$(printf %s "\"vmess://${uri_tcp}\"" | tr -d '\n')"

  echo "${V2_DOMAIN}:443"
  echo "${uuid_tcp} (aid: 0)" && echo ""
  display_vmess

  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare') != "true" ]]; then
    read -p "设置 CDN (yes/no)? " wssConfirm
    case "${wssConfirm}" in
      y|Y|[yY][eE][sS] ) set_v2ray_wss_prompt ;;
    esac
  fi

  subscription_prompt
}

get_trojan() {
  if [ ! -f "/usr/bin/trojan-go" ]; then
    colorEcho ${BLUE} "trojan-go is not installed. start installation"

    colorEcho ${BLUE} "Getting the latest version of trojan-go"
    local latest_version="$(curl -s "https://api.github.com/repos/p4gefau1t/trojan-go/releases" | jq '.[0].tag_name' --raw-output)"
    echo "latest_version"
    local trojan-go_link=$(https://github.com/p4gefau1t/trojan-go/releases/download/${latest_version}/trojan-go-linux-amd64.zip)

    cd $(mktemp -d)
    wget ${trojan-go_link} -O trojan-go.zip
    unzip trojan-go.zip && rm -rf trojan-go.zip
    ${sudoCmd} mv trojan-go /usr/bin/trojan-go

    colorEcho ${BLUE} "Building trojan-go.service"
    ${sudoCmd} mv example/trojan-go.service /etc/systemd/system/trojan-go.service

    # set crontab to auto update geoip.dat and geosite.dat
    (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/bin/trojan-go/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
    (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/bin/trojan-go/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -

    colorEcho ${GREEN} "trojan-go is installed."
  else
    colorEcho ${BLUE} "Getting the latest version of trojan-go"
    local latest_version="$(curl -s "https://api.github.com/repos/p4gefau1t/trojan-go/releases" | jq '.[0].tag_name' --raw-output)"
    echo "latest_version"
    local trojan-go_link=$(https://github.com/p4gefau1t/trojan-go/releases/download/${latest_version}/trojan-go-linux-amd64.zip)
    cd $(mktemp -d)
    wget ${trojan-go_link} -O trojan-go.zip
    unzip trojan-go.zip
    ${sudoCmd} mv trojan-go /usr/bin/trojan-go/trojan-go
  fi
}

install_trojan() {
  read -p "解析到本 VPS 的域名: " TJ_DOMAIN
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
    if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader') == "${TJ_DOMAIN}" ]] || [[ $(read_json /usr/local/etc/v2script/config.json '.sub.api.tlsHeader') == "${TJ_DOMAIN}" ]]; then
      colorEcho ${RED} "域名 ${TJ_DOMAIN} 与现有域名重复,  请使用别的域名"
      show_menu
      return 1
    fi
  fi
  write_json /usr/local/etc/v2script/config.json ".trojan.tlsHeader" "\"${TJ_DOMAIN}\""

  get_trojan

  # create config files
  if [ ! -f "/etc/trojan-go/config.json" ]; then
    colorEcho ${BLUE} "Setting trojan-go"
    wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/trojan-go.json -O /tmp/trojan-go.json
    sed -i "s/FAKETROJANPWD/$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 12)/g" /tmp/trojan-go.json
    ${sudoCmd} /bin/cp -f /tmp/trojan-go.json /etc/trojan-go/config.json
  fi

  colorEcho ${BLUE} "Setting tls-shunt-proxy"
  set_proxy

  colorEcho ${BLUE} "Setting caddy"
  set_caddy

  colorEcho ${BLUE} "Building dummy web site"
  build_web

  # activate services
  colorEcho ${BLUE} "Activating services"
  ${sudoCmd} systemctl enable trojan-go
  ${sudoCmd} systemctl restart trojan-go 2>/dev/null ## restart trojan-go  to enable new config
  ${sudoCmd} systemctl enable tls-shunt-proxy
  ${sudoCmd} systemctl restart tls-shunt-proxy ## restart tls-shunt-proxy to enable new config
  ${sudoCmd} systemctl enable caddy
  ${sudoCmd} systemctl restart caddy
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  colorEcho ${GREEN} "安装 trojan-go 成功!"

  subscription_prompt
}

rm_v2script() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/rm_v2script.sh | bash
  exit 0
}

display_mtproto() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader') == "" ]] &&  [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ]];then
    echo "tg://proxy?server=`curl -s https://api.ipify.org`&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  elif  [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]] &&  [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ]];then
    echo "tg://proxy?server=$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  fi
}

install_mtproto() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.installed') != "true" ]]; then
    get_proxy
    get_docker

    # pre-run this to pull image
    ${sudoCmd} docker run --rm nineseconds/mtg generate-secret tls -c "www.fast.com" >/dev/null

    # generate random header from txt files
    local FAKE_TLS_HEADER="$(curl -s https://raw.githubusercontent.com/phlinhng/my-scripts/master/text/mainland_cdn.txt | shuf -n 1)"
    local secret="$(${sudoCmd} docker run --rm nineseconds/mtg generate-secret tls -c ${FAKE_TLS_HEADER})"

    # writing configurations & setting tls-shunt-proxy
    write_json "/usr/local/etc/v2script/config.json" ".mtproto.installed" "true"
    write_json "/usr/local/etc/v2script/config.json" ".mtproto.fakeTlsHeader" "\"${FAKE_TLS_HEADER}\""
    write_json "/usr/local/etc/v2script/config.json" ".mtproto.secret" "\"${secret}\""

    set_proxy
    set_docker

    # activate service
    ${sudoCmd} systemctl enable docker
    ${sudoCmd} systemctl start docker
    ${sudoCmd} systemctl enable tls-shunt-proxy
    ${sudoCmd} systemctl restart tls-shunt-proxy
    ${sudoCmd} systemctl daemon-reload
    colorEcho ${GREEN} "电报代理设置成功!"
  fi

  display_mtproto
}

check_status() {
  printf "目前配置: "
  if [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    colorEcho ${GREEN} "V2Ray (TCP+TLS, WSS+CDN), Trojan"
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.cloudflare')" == "true" ]]; then
    colorEcho ${GREEN} "V2Ray (TCP+TLS, WSS+CDN)"
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]] && [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    colorEcho ${GREEN} "V2Ray (TCP+TLS), Trojan"
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.v2ray.installed')" == "true" ]]; then
    colorEcho ${GREEN} "V2Ray (TCP+TLS)"
  elif [[ "$(read_json /usr/local/etc/v2script/config.json '.trojan.installed')" == "true" ]]; then
    colorEcho ${GREEN} "Trojan"
  else
    colorEcho ${YELLOW} "未安装代理"
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.enabled') == "true" ]]; then
    printf '%s\n' "订阅链接: "
    colorEcho ${GREEN} "$(display_link_main)"
  fi

  printf "电报代理: "
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') != "true" ]] && [[ $(read_json /usr/local/etc/v2script/config.json '.trojan.installed') != "true" ]] && [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ]];then
    colorEcho ${GREEN} "tg://proxy?server=`curl -s https://api.ipify.org`&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  elif [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]] &&  [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ]];then
    colorEcho ${GREEN} "tg://proxy?server=$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  elif [[ $(read_json /usr/local/etc/v2script/config.json '.trojan.installed') == "true" ]] &&  [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ]];then
    colorEcho ${GREEN} "tg://proxy?server=$(read_json /usr/local/etc/v2script/config.json '.trojan.tlsHeader')&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  else
    colorEcho ${YELLOW} "未设置"
  fi

  if [[ ! $(cat /proc/swaps | wc -l) -gt 1 ]]; then
    echo ""
    colorEcho ${YELLOW} "检测到 Swap 未开启 建议启用"
  fi

  if [ -f /usr/sbin/aliyun-service ]; then
    colorEcho ${RED} "检测到阿里云监测服务 建议卸载"
  fi

  echo ""
}

vps_tools() {
  ${sudoCmd} ${systemPackage} install wget -y -qq
  wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/vps_tools.sh -O /tmp/vps_tools.sh && chmod +x /tmp/vps_tools.sh && ${sudoCmd} /tmp/vps_tools.sh
  exit 0
}

menu() {
  colorEcho ${YELLOW} "V2Ray & Trojan automated script v${VERSION}"
  colorEcho ${YELLOW} "author: phlinhng"
  echo ""

  check_status
  show_menu

  #PS3="选择操作[输入任意值或按Ctrl+C退出]: "
  COLUMNS=woof
  #options=("安装TCP+TLS+WEB" "显示vmess链接" "管理订阅" "设置CDN" "设置电报代理" "VPS工具" "更新v2ray-core" "更新tls-shunt-proxy" "卸载TCP+TLS+WEB")
  #select opt in "${options[@]}"
  read -rp "选择操作 [输入任意值或按 Ctrl+C 退出]: " opt
  do
    case "${opt}" in
      "0") install_v2ray && continue_prompt ;;
      "1") install_trojan && continue_prompt ;;
      "2") display_vmess && continue_prompt ;;
      "3") v2sub && exit 0 ;;
      "4") set_v2ray_wss_prompt && continue_prompt ;;
      "5") install_mtproto && continue_prompt ;;
      "6") vps_tools ;;
      "7") get_v2ray && continue_prompt ;;
      "8") get_proxy && continue_prompt ;;
      "9") get_trojan && continue_prompt ;;
      "10") rm_v2script ;;
      *) break ;;
    esac
  done

}

menu