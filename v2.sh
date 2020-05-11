#!/bin/bash

# lite version

export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8

branch="master"

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

read_json() {
  # jq [key] [path-to-file]
  ${sudoCmd} jq --raw-output $2 $1 2>/dev/null | tr -d '\n'
} ## read_json [path-to-file] [key]

write_json() {
  # jq [key = value] [path-to-file]
  jq -r "$2 = $3" $1 > tmp.$$.json && ${sudoCmd} mv tmp.$$.json $1 && sleep 1
} ## write_json [path-to-file] [key = value]

display_vmess() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.install') != "true" ]]; then
    uuid="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
    V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"
    json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${V2_DOMAIN}:443\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    uri="$(printf "${json}" | base64)"
    echo "vmess://${uri}" | tr -d '\n' && printf "\n"
  else
    colorEcho ${RED} "配置文件不存在"
    return 1
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

get_proxy() {
  if [ ! -f "/usr/local/bin/tls-shunt-proxy" ]; then
    colorEcho ${BLUE} "tls-shunt-proxy is not installed. start installation"
    curl -sL https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/dist/install.sh | ${sudoCmd} bash
    colorEcho ${GREEN} "tls-shunt-proxy is installed."
  fi
}

get_v2ray() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://install.direct/go.sh | ${sudoCmd} bash
}

install_v2ray() {
  read -p "解析到本VPS的域名: " V2_DOMAIN
  write_json /usr/local/etc/v2script/config.json ".v2ray.tlsHeader" "\"${V2_DOMAIN}\""

  # install requirements
  # coreutils: for base64 command
  # uuid-runtime: for uuid generating
  # ntp: time syncronise service
  # jq: json toolkits
  # unzip: to decompress web templates
  ${sudoCmd} ${systemPackage} update -qq
  ${sudoCmd} ${systemPackage} install curl coreutils wget ntp jq uuid-runtime unzip -y -qq

  cd $(mktemp -d)
  wget -q https://github.com/phlinhng/v2ray-tcp-tls-web/archive/${branch}.zip
  unzip -q ${branch}.zip && rm -f ${branch}.zip ## will unzip the source to current path and remove the archive file
  cd v2ray-tcp-tls-web-${branch}

  if [ ! -d "/usr/local/etc/v2script" ]; then
    mkdir -p /usr/local/etc/v2script ## folder for scripts configuration
  elif [ ! -f "/usr/local/etc/v2script/config.json" ]; then
    wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/v2scirpt.json -O /usr/local/etc/v2script/config.json
  fi

  # install v2ray-core
  if [ ! -d "/usr/bin/v2ray" ]; then
    get_v2ray
    colorEcho ${BLUE} "Building v2ray.service for domainsocket"
    ds_service=$(mktemp)
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
# Don't restart in the case of configuration error
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    # add new user and overwrite v2ray.service
    # https://github.com/v2ray/v2ray-core/issues/1011
    ${sudoCmd} useradd -d /etc/v2ray/ -M -s /sbin/nologin v2ray
    ${sudoCmd} mv ${ds_service} /etc/systemd/system/v2ray.service
    ${sudoCmd} chown -R v2ray:v2ray /var/log/v2ray
  fi

  # install tls-shunt-proxy
  get_proxy

  # install docker
  get_docker

  # prevent some bug
  ${sudoCmd} rm -rf /var/www/html

  # create config files
  colorEcho ${BLUE} "Setting v2Ray"
  sed -i "s/FAKEPORT/$(read_json /etc/v2ray/config.json '.inbounds[0].port')/g" ./config/v2ray.json
  sed -i "s/FAKEUUID/$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')/g" ./config/v2ray.json
  ${sudoCmd} /bin/cp -f ./config/v2ray.json /etc/v2ray/config.json

  colorEcho ${BLUE} "Setting tls-shunt-proxy"
  ${sudoCmd} /bin/cp /etc/tls-shunt-proxy/config.yaml /etc/tls-shunt-proxy/config.yaml.bak 2>/dev/null
  sed -i "s/FAKEV2DOMAIN/${V2_DOMAIN}/g" ./config/config.yaml
  sed -i "s/##V2RAY@//g" ./config/config.yaml
  ${sudoCmd} /bin/cp -f ./config/config.yaml /etc/tls-shunt-proxy/config.yaml

  colorEcho ${BLUE} "Setting caddy"
  sed -i "s/FAKEV2DOMAIN/${V2_DOMAIN}/g" ./config/Caddyfile
  /bin/cp -f ./config/Caddyfile /usr/local/etc

  # choose and copy a random  template for dummy web pages
  colorEcho ${BLUE} "Building dummy web site"
  template="$(curl -s https://raw.githubusercontent.com/phlinhng/web-templates/master/list.txt | shuf -n  1)"
  wget -q https://raw.githubusercontent.com/phlinhng/web-templates/master/${template}
  ${sudoCmd} mkdir -p /var/www/html
  ${sudoCmd} unzip -q ${template} -d /var/www/html
  ${sudoCmd} /bin/cp -f ./custom/robots.txt /var/www/html/robots.txt

  # set crontab to auto update geoip.dat and geosite.dat
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/bin/v2ray/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/bin/v2ray/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -

  # stop nginx service for user who had used the old version of script
  #${sudoCmd} systemctl stop nginx 2>/dev/null
  #${sudoCmd} systemctl disable nginx 2>/dev/null

  # kill process occupying port 80
  #${sudoCmd} kill -9 $(lsof -t -i:80) 2>/dev/null

  # activate services
  colorEcho ${BLUE} "Activating services"
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl enable ntp
  ${sudoCmd} systemctl restart ntp
  ${sudoCmd} systemctl enable docker
  ${sudoCmd} systemctl restart docker
  ${sudoCmd} systemctl enable v2ray
  ${sudoCmd} systemctl restart v2ray
  ${sudoCmd} systemctl enable tls-shunt-proxy
  ${sudoCmd} systemctl restart tls-shunt-proxy
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  # activate caddy
  colorEcho ${BLUE} "Activating caddy"
  ${sudoCmd} docker run -d --restart=always -v /usr/local/etc/Caddyfile:/etc/Caddyfile -v $HOME/.caddy:/root/.caddy -p 80:80 abiosoft/caddy

  colorEcho ${GREEN} "安装TCP+TLS+WEB成功!"
  uuid="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"

  echo "${V2_DOMAIN}:443"
  echo "${uuid} (aid: 0)"
  echo ""

  json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${V2_DOMAIN}:443\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
  uri="$(printf "${json}" | base64)"

  echo "vmess://${uri}" | tr -d '\n' && printf "\n"
}

install_v2ray
