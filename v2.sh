#!/bin/bash

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
  colorEcho ${RED} "unsupported OS"
  exit 0
elif cat /etc/issue | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
  colorEcho ${RED} "unsupported OS"
  exit 0
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
  colorEcho ${RED} "unsupported OS"
  exit 0
fi

# a trick to redisplay menu option
show_menu() {
  echo ""
  echo "1) 安装TCP+TLS+WEB"
  echo "2) 更新v2Ray-core"
  echo "3) 卸载TCP+TLS+WEB"
  echo "4) 显示vmess链接"
  echo "5) 生成订阅"
  echo "6) 更新订阅"
  echo "7) 安装加速脚本"
  echo "8) 设置Swap"
}

continue_prompt() {
  read -p "继续其他操作 (yes/no)? " choice
  case "${choice}" in
    y|Y|[yY][eE][sS] ) show_menu ;;
    * ) exit 0;;
  esac
}

display_vmess() {
  if [ ! -d "/usr/bin/v2ray" ]; then
    colorEcho ${RED} "尚末安装v2Ray"
    return 1
  elif [ ! -f "/usr/local/etc/v2script/tls-header" ]; then
    colorEcho ${RED} "web server配置文件不存在"
    return 1
  fi

  #${sudoCmd} ${systemPackage} install coreutils jq -y
  uuid="$(${sudoCmd} cat /etc/v2ray/config.json | jq --raw-output '.inbounds[0].settings.clients[0].id')"
  V2_DOMAIN="$(${sudoCmd} cat /usr/local/etc/v2script/tls-header | grep -e 'server_name' | sed -e 's/^[[:blank:]]server_name[[:blank:]]//g' -e 's/;//g' | tr -d '\n')"

  echo "${V2_DOMAIN}:443"
  echo "${uuid} (aid: 0)"
  echo ""

  json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${V2_DOMAIN}:443\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"

  uri="$(printf "${json}" | base64)"
  echo "vmess://${uri}" | tr -d '\n' && printf "\n"
}

generate_link() {
  if [ ! -d "/usr/bin/v2ray" ]; then
    colorEcho ${RED} "尚末安装v2Ray"
    return 1
  elif [ ! -f "/usr/local/etc/v2script/tls-header" ]; then
    colorEcho ${RED} "web server配置文件不存在"
    return 1
  fi

  if [ -f "/usr/local/etc/v2script/subscription" ]; then
    ${sudoCmd} rm -f /var/www/html/$(${sudoCmd} cat /usr/local/etc/v2script/subscription)
  fi

  #${sudoCmd} ${systemPackage} install uuid-runtime coreutils jq -y
  uuid=$(${sudoCmd} cat /etc/v2ray/config.json | jq --raw-output '.inbounds[0].settings.clients[0].id')
  V2_DOMAIN=$(${sudoCmd} cat /usr/local/etc/v2script/tls-header | grep -e 'server_name' | sed -e 's/^[[:blank:]]server_name[[:blank:]]//g' -e 's/;//g' | tr -d '\n')

  read -p "输入节点名称[留空则使用默认值]: " remark

  if [ -z "${remark}" ]; then
    remark="${V2_DOMAIN}:443"
  fi

  json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${remark}\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"

  uri="$(printf "${json}" | base64)"
  vmess="vmess://${uri}"
  sub="$(printf "vmess://${uri}" | tr -d '\n' | base64)"

  randomName="$(uuidgen | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 16)" #random file name for subscription
  printf "${randomName}" | ${sudoCmd} tee /usr/local/etc/v2script/subscription >/dev/null
  printf "${sub}" | tr -d '\n' | ${sudoCmd} tee -a /var/www/html/${randomName} >/dev/null
  echo "https://${V2_DOMAIN}/${randomName}" | tr -d '\n' && printf "\n"
}

get_v2ray() {
  ${sudoCmd} ${systemPackage} install curl -y
  # install v2ray
  curl -L -s https://install.direct/go.sh | ${sudoCmd} bash
}

install_v2ray() {
  read -p "解析到本VPS的域名: " V2_DOMAIN

  # install requirements
  # coreutils: for base64 command
  # uuid-runtime: for uuid generating
  # ntp: time syncronise service
  # jq: json toolkits
  ${sudoCmd} ${systemPackage} update
  ${sudoCmd} ${systemPackage} install curl git coreutils wget ntp jq uuid-runtime -y

  # install v2ray-core
  if [ ! -d "/usr/bin/v2ray" ]; then
    get_v2ray
  fi

  # install tls-shunt-proxy
  if [ ! -f "/usr/local/bin/tls-shunt-proxy" ]; then
    curl -L -s https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/dist/install.sh | ${sudoCmd} bash
    colorEcho ${GREEN} "tls-shunt-proxy is installed."
  fi

  # install docker
  curl -sSL https://get.docker.com/ | ${sudoCmd} sh
  # install docker-compose
  #${sudoCmd} curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  #${sudoCmd}  chmod +x /usr/local/bin/docker-compose

  # folder for scripts configuration
  mkdir -p /usr/local/etc/v2script

  cd $(mktemp -d)
  git clone https://github.com/phlinhng/v2ray-tcp-tls-web.git
  cd v2ray-tcp-tls-web

  # prevent some bug
  ${sudoCmd} rm -rf /etc/tls-shunt-proxy
  ${sudoCmd} mkdir -p /etc/tls-shunt-proxy

  # create config files
  uuid=$(${sudoCmd} cat /etc/v2ray/config.json | jq --raw-output '.inbounds[0].settings.clients[0].id')
  sed -i "s/FAKEUUID/${uuid}/g" ./config_template/config.json
  sed -i "s/FAKEDOMAIN/${V2_DOMAIN}/g" ./config_template/config.yaml
  sed -i "s/FAKEDOMAIN/${V2_DOMAIN}/g" ./config_template/Caddyfile
  printf "${V2_DOMAIN}" | tr -d '\n' | ${sudoCmd} tee /usr/local/etc/v2script/tls-header

  # copy cofig files to respective path
  ${sudoCmd} /bin/cp -f ./config_template/config.json /etc/v2ray/config.json
  ${sudoCmd} /bin/cp -f ./config_template/config.yaml /etc/tls-shunt-proxy/config.yaml
  ${sudoCmd} /bin/cp -f ./config_template/Caddyfile /usr/local/etc/Caddyfile

  # copy template for dummy web pages
  ${sudoCmd} mkdir -p /var/www/html
  ${sudoCmd} /bin/cp -rf web_template/templated-industrious/. /var/www/html

  # set crontab to auto update geoip.dat and geosite.dat
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/bin/v2ray/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/bin/v2ray/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -

  # activate caddy
  ${sudoCmd} docker run -d --restart=always -v /usr/local/etc/Caddyfile:/etc/Caddyfile -v $HOME/.caddy:/root/.caddy -p 80:80 abiosoft/caddy

  # activate services
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl enable ntp
  ${sudoCmd} systemctl start ntp
  ${sudoCmd} systemctl enable docker
  ${sudoCmd} systemctl start docker
  ${sudoCmd} systemctl enable v2ray
  ${sudoCmd} systemctl start v2ray
  ${sudoCmd} systemctl enable tls-shunt-proxy
  ${sudoCmd} systemctl start tls-shunt-proxy

  # remove installation files
  cd ..
  rm -rf v2ray-tcp-tls-web

  colorEcho ${GREEN} "安装TCP+TLS+WEB成功!"
  display_vmess

  read -p "生成订阅链接 (yes/no)? " linkConfirm
  case "${linkConfirm}" in
    y|Y|[yY][eE][sS] ) generate_link ;;
    * ) return 0;;
  esac
}

rm_v2ray() {
  if [ ! -d "/usr/bin/v2ray" ] || [ ! -f "/usr/local/bin/tls-shunt-proxy" ]; then
    return 1
  fi

  ${sudoCmd} ${systemPackage} install curl -y

  # remove v2ray
  # Notice the two dashes (--) which are telling bash to not process anything following it as arguments to bash.
  # https://stackoverflow.com/questions/4642915/passing-parameters-to-bash-when-executing-a-script-fetched-by-curl
  curl -sL https://install.direct/go.sh | ${sudoCmd} bash -s -- --remove
  ${sudoCmd} rm -rf /etc/v2ray

  # remove tls-shunt-server
  colorEcho ${BLUE} "Shutting down tls-shunt-proxy service."
  ${sudoCmd} systemctl stop tls-shunt-proxy
  ${sudoCmd} systemctl disable tls-shunt-proxy
  ${sudoCmd} rm -f /etc/systemd/system/tls-shunt-proxy.service
  ${sudoCmd} rm -f /etc/systemd/system/tls-shunt-proxy.service # and symlinks that might be related
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed
  colorEcho ${BLUE} "Removing tls-shunt-proxy files."
  ${sudoCmd} rm -rf /usr/local/bin/tls-shunt-proxy
  ${sudoCmd} rm -rf /etc/ssl/tls-shunt-proxy
  colorEcho ${BLUE} "Removing tls-shunt-proxy user & group."
  ${sudoCmd} deluser tls-shunt-proxy
  ${sudoCmd} delgroup --only-if-empty tls-shunt-proxy
  colorEcho ${GREEN} "Removed tls-shunt-proxy successfully."

  # docker
  colorEcho ${BLUE} "Shutting down docker service."
  ${sudoCmd} systemctl stop docker
  ${sudoCmd} systemctl disable docker
  colorEcho ${BLUE} "Removing docker containers, images, networks, and images"
  ${sudoCmd} docker container prune --force
  ${sudoCmd} docker image prune --force
  ${sudoCmd} docker volume prune --force
  ${sudoCmd} docker network prune
  colorEcho ${GREEN} "Removed docker successfully."

  # remove script configuration files
  ${sudoCmd} rm -rf /usr/local/etc/v2script

  exit 0
}

update_link() {
  if [ ! -d "/usr/bin/v2ray" ]; then
    colorEcho ${RED} "尚末安装v2Ray"
    return 1
  elif [ ! -f "/usr/local/etc/v2script/tls-header" ]; then
    colorEcho ${RED} "web server配置文件不存在"
    return 1
  fi

  if [ -f "/usr/local/etc/v2script/subscription" ]; then
    subFileName="$(${sudoCmd} cat /usr/local/etc/v2script/subscription)"
    uuid=$(${sudoCmd} cat /etc/v2ray/config.json | jq --raw-output '.inbounds[0].settings.clients[0].id')
    V2_DOMAIN=$(${sudoCmd} cat /usr/local/etc/v2script/tls-header | grep -e 'server_name' | sed -e 's/^[[:blank:]]server_name[[:blank:]]//g' -e 's/;//g' | tr -d '\n')
    currentRemark="$(cat /var/www/html/${subFileName} | base64 -d | sed 's/^vmess:\/\///g' | base64 -d | jq --raw-output '.ps' | tr -d '\n')"

    read -p "输入节点名称[留空则使用现有值 ${currentRemark}]: " remark

    if [ -z "${remark}" ]; then
      remark="${currentRemark}"
    fi

    json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${remark}\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"

    uri="$(printf "${json}" | base64)"
    vmess="vmess://${uri}"
    sub="$(printf "vmess://${uri}" | tr -d '\n' | base64)"

    printf "${sub}" | tr -d '\n' | ${sudoCmd} tee /var/www/html/${subFileName} >/dev/null
    echo "https://${V2_DOMAIN}/${subFileName}" | tr -d '\n' && printf "\n"

    colorEcho ${GREEN} "更新订阅完成"
  else
    generate_link
  fi

}

get_netSpeed() {
  ${sudoCmd} ${systemPackage} install wget -y
  cd $(mktemp -d)
  wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"
  chmod +x tcp.sh
  ${sudoCmd} ./tcp.sh
  exit 0
}

check_status() {
  printf "TCP+TLS+WEB状态: "
  if [ -d "/usr/bin/v2ray" ] && [ -f "/usr/local/bin/tls-shunt-proxy" ] && [ -f "/usr/local/etc/v2script/Caddyfile" ]; then
    colorEcho ${GREEN} "己安装"
  else
    colorEcho ${YELLOW} "未安装"
  fi

  if [ -f "/usr/local/etc/v2script/subscription" ] && [ -f "/usr/local/etc/v2script/tls-header" ]; then
    printf "主订阅链接: "
    colorEcho ${YELLO} "https://$(${sudoCmd} cat /usr/local/etc/v2script/tls-header)/$(${sudoCmd} cat /usr/local/etc/v2script/subscription)"
  fi

  echo ""
  printf "Swap状态: "
  if [[ ! $(cat /proc/swaps | wc -l) -gt 1 ]]; then
    colorEcho ${GREEN} "己开启"
  else
    colorEcho ${YELLOW} "未开启"
  fi

  if [ ! -d /usr/sbin/aliyun-service ]; then
    echo ""
    colorEcho ${RED} "检测到阿里云监测服务 建议卸载"
  fi

  echo ""
}

menu() {
  colorEcho ${YELLOW} "v2Ray TCP+TLS+WEB automated script v0.3.1"
  colorEcho ${YELLOW} "author: phlinhng"
  echo ""

  check_status

  PS3="选择操作[输入任意值或按Ctrl+C退出]: "
  COLUMNS=12
  options=("安装TCP+TLS+WEB" "更新v2Ray-core" "卸载TCP+TLS+WEB" "显示vmess链接" "生成订阅" "更新订阅" "安装加速脚本" "设置Swap" "卸载阿里云盾")
  select opt in "${options[@]}"
  do
    case "${opt}" in
      "安装TCP+TLS+WEB") install_v2ray && continue_prompt ;;
      "更新v2Ray-core") get_v2ray && continue_prompt ;;
      "卸载TCP+TLS+WEB") rm_v2ray ;;
      "显示vmess链接") display_vmess && continue_prompt ;;
      "生成订阅") generate_link && continue_prompt ;;
      "更新订阅") update_link && continue_prompt ;;
      "安装加速脚本") get_netSpeed;;
      "设置Swap") chmod +x ./tools/set_swap.sh && ./tools/set_swap.sh && continue_prompt ;;
      "卸载阿里云盾") chmod +x ./tools/rm_aliyundun && ./tools/rm_aliyundun.sh && continue_prompt ;;
      *) break;;
    esac
  done

}

menu
