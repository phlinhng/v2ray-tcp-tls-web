#!/bin/bash

branch="beta"

# /usr/local/etc/v2script ##config path
# /usr/local/etc/v2script/tls-header ##domain for v2Ray
# /usr/local/etc/v2script/subscription ##filename of main subscription
# /usr/local/etc/v2script/Caddyfile ##config of caddy
# /usr/local/etc/v2script/mtproto-header  ##domain for mtproto
# /usr/local/etc/v2script/mtproto-secret  ##secret for mtproto

# /usr/local/bin/v2script ##main
# /usr/local/bin/v2sub ##subscription manager

# todo: use /usr/local/etc/v2script/script.json as config

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

# a trick to redisplay menu option
show_menu() {
  echo ""
  echo "1) 安装TCP+TLS+WEB"
  echo "2) 更新v2Ray-core"
  echo "3) 卸载TCP+TLS+WEB"
  echo "4) 显示vmess链接"
  echo "5) 管理订阅"
  echo "6) 设置电报代理"
  echo "7) VPS工具"
}

continue_prompt() {
  read -p "继续其他操作 (yes/no)? " choice
  case "${choice}" in
    y|Y|[yY][eE][sS] ) show_menu ;;
    * ) exit 0;;
  esac
}

read_json() {
  ${sudoCmd} jq --raw-output $1 $2 2>/dev/null | tr -d '\n'
}

display_vmess() {
  if [ ! -d "/usr/bin/v2ray" ]; then
    colorEcho ${RED} "尚末安装v2Ray"
    return 1
  elif [ ! -f "/usr/local/etc/v2script/config.json" ]; then
    colorEcho ${RED} "配置文件不存在"
    return 1
  fi

  #${sudoCmd} ${systemPackage} install coreutils jq -y
  uuid="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
  V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"

  echo "${V2_DOMAIN}:443"
  echo "${uuid} (aid: 0)"
  echo ""

  json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${V2_DOMAIN}:443\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
  uri="$(printf "${json}" | base64)" # todo: add link to v2script config

  echo "vmess://${uri}" | tr -d '\n' && printf "\n"
}

generate_link() {
  if [ ! -d "/usr/bin/v2ray" ]; then
    colorEcho ${RED} "尚末安装v2Ray"
    return 1
  elif [ ! -f "/usr/local/etc/v2script/config.json" ]; then
    colorEcho ${RED} "配置文件不存在"
    return 1
  fi

  if [ -f "/usr/local/etc/v2script/subscription" ]; then
    ${sudoCmd} rm -f /var/www/html/$(${sudoCmd} cat /usr/local/etc/v2script/subscription)
  fi

  #${sudoCmd} ${systemPackage} install uuid-runtime coreutils jq -y
  uuid="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
  V2_DOMAIN="$(${sudoCmd} cat /usr/local/etc/v2script/tls-header | tr -d '\n')"

  read -p "输入节点名称[留空则使用默认值]: " remark

  if [ -z "${remark}" ]; then
    remark="${V2_DOMAIN}:443"
  fi

  json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${remark}\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"

  uri="$(printf "${json}" | base64)"
  sub="$(printf "vmess://${uri}" | tr -d '\n' | base64)"

  randomName="$(uuidgen | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 16)" #random file name for subscription
  printf "${randomName}" | ${sudoCmd} tee /usr/local/etc/v2script/subscription >/dev/null
  printf "${sub}" | tr -d '\n' | ${sudoCmd} tee -a /var/www/html/${randomName} >/dev/null
  echo "https://${V2_DOMAIN}/${randomName}" | tr -d '\n' && printf "\n"
}

get_v2ray() {
  ${sudoCmd} ${systemPackage} install curl -y
  # install v2ray
  curl -sSL https://install.direct/go.sh | ${sudoCmd} bash
}

install_v2ray() {
  read -p "解析到本VPS的域名: " V2_DOMAIN

  # install requirements
  # coreutils: for base64 command
  # uuid-runtime: for uuid generating
  # ntp: time syncronise service
  # jq: json toolkits
  # unzip: to decompress web templates
  ${sudoCmd} ${systemPackage} update
  ${sudoCmd} ${systemPackage} install curl git coreutils wget ntp jq uuid-runtime unzip -y

  # install v2ray-core
  if [ ! -d "/usr/bin/v2ray" ]; then
    get_v2ray
  fi

  # install tls-shunt-proxy
  if [ ! -f "/usr/local/bin/tls-shunt-proxy" ]; then
    curl -sSL https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/dist/install.sh | ${sudoCmd} bash
    colorEcho ${GREEN} "tls-shunt-proxy is installed."
  if [ -f "/etc/tls-shunt-proxy/config.yaml" ]; then # tls-shunt-proxy installed and config.yaml exists
    ${sudoCmd} cat /etc/tls-shunt-proxy/config.yaml | ${sudoCmd} tee /etc/tls-shunt-proxy/config.yaml.bak
    ${sudoCmd} cat /etc/tls-shunt-proxy/config.yaml | ${sudoCmd} tee config-new.yaml
    cd $(mktemp -d)
    sed -i "s/FAKEV2DOMAIN/${V2_DOMAIN}/g" config-new.yaml
    sed -i "s/##V2RAY@//g" config-new.yaml
    ${sudoCmd} /bin/cp -f config-new.yaml /etc/tls-shunt-proxy/config.yaml
  fi

  # install docker
  curl -sSL https://get.docker.com/ | ${sudoCmd} bash
  # install docker-compose
  #${sudoCmd} curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  #${sudoCmd}  chmod +x /usr/local/bin/docker-compose

  cd $(mktemp -d)
  git clone https://github.com/phlinhng/v2ray-tcp-tls-web.git
  cd v2ray-tcp-tls-web
  git checkout ${branch}

  # prevent some bug
  ${sudoCmd} rm -rf /etc/ssl/tls-shunt-proxy
  ${sudoCmd} rm -rf /etc/tls-shunt-proxy
  ${sudoCmd} mkdir -p /etc/tls-shunt-proxy
  ${sudoCmd} rm -rf /usr/local/etc/v2script
  ${sudoCmd} rm -rf /var/www/html

  # folder for scripts configuration
  ${sudoCmd} mkdir -p /usr/local/etc/v2script

  # create config files
  uuid=$(${sudoCmd} cat /etc/v2ray/config.json | jq --raw-output '.inbounds[0].settings.clients[0].id')
  sed -i "s/FAKEUUID/${uuid}/g" ./config/v2ray.json
  sed -i "s/##V2RAY@//g" ./config/config.yaml
  sed -i "s/FAKEV2DOMAIN/${V2_DOMAIN}/g" ./config/config.yaml
  sed -i "s/FAKEV2DOMAIN/${V2_DOMAIN}/g" ./config/Caddyfile
  printf "${V2_DOMAIN}" | tr -d '\n' | ${sudoCmd} tee /usr/local/etc/v2script/tls-header

  # copy cofig files to respective path
  ${sudoCmd} /bin/cp -f ./config/v2ray.json /etc/v2ray/config.json
  ${sudoCmd} /bin/cp -f ./config/config.yaml /etc/tls-shunt-proxy/config.yaml
  ${sudoCmd} /bin/cp -f ./config/Caddyfile /usr/local/etc/Caddyfile

  # choose and copy a random  template for dummy web pages
  template="$(curl -s https://raw.githubusercontent.com/phlinhng/web-templates/master/list.txt | shuf -n  1)"
  wget -q https://raw.githubusercontent.com/phlinhng/web-templates/master/${template} -O template.zip
  ${sudoCmd} mkdir -p /var/www/html
  ${sudoCmd} unzip template.zip -d /var/www/html

  # set crontab to auto update geoip.dat and geosite.dat
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/bin/v2ray/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/bin/v2ray/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -

  # activate caddy
  ${sudoCmd} docker run -d --restart=always -v /usr/local/etc/Caddyfile:/etc/Caddyfile -v $HOME/.caddy:/root/.caddy -p 80:80 abiosoft/caddy

  # activate services
  ${sudoCmd} systemctl enable ntp
  ${sudoCmd} systemctl restart ntp
  ${sudoCmd} systemctl enable docker
  ${sudoCmd} systemctl restart docker
  ${sudoCmd} systemctl enable v2ray
  ${sudoCmd} systemctl restart v2ray
  ${sudoCmd} systemctl enable tls-shunt-proxy
  ${sudoCmd} systemctl restart tls-shunt-proxy
  ${sudoCmd} systemctl daemon-reload

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

rm_v2script() {
  ${sudoCmd} ${systemPackage} install curl -y
  curl -sSL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/rm_v2script.sh | bash
  exit 0
}

get_v2sub() {
  if [ ! -f "/usr/local/bin/v2sub" ]; then
    ${sudoCmd} ${systemPackage} update
    ${sudoCmd} ${systemPackage} install wget -y
    wget https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/v2sub.sh -O /usr/local/bin/v2sub
    chmod +x /usr/local/bin/v2sub
  else
    /usr/local/bin/v2sub
  fi
}

install_mtproto() {
  if [ ! -f "/usr/local/etc/v2script/mtproto-header" ] && [ ! -f "/usr/local/etc/v2script/mtproto-secret" ]; then
    ${sudoCmd} ${systemPackage} update
    ${sudoCmd} ${systemPackage} install curl -y

    curl -sSL https://get.docker.com/ | ${sudoCmd} bash

    # generate random header from txt files
    FAKE_TLS_HEADER="$(curl -s https://raw.githubusercontent.com/phlinhng/my-scripts/master/text/mainland_cdn.txt | shuf -n 1)"
    secret="$(${sudoCmd} docker run --rm nineseconds/mtg generate-secret tls -c "${FAKE_TLS_HEADER}")"

    # start mtproto ## reference https://raw.githubusercontent.com/9seconds/mtg/master/run.sh
    ${sudoCmd} docker run -d --restart=always --name mtg --ulimit nofile=51200:51200 -p 127.0.0.1:3128:3128 nineseconds/mtg:latest run "${secret}"

    printf "${FAKE_TLS_HEADER}" | tr  -d '\n' | ${sudoCmd} tee /usr/local/etc/v2script/mtproto-header >/dev/null
    printf "${secret}" | tr  -d '\n' | ${sudoCmd} tee /usr/local/etc/v2script/mtproto-secret >/dev/null

    if [ ! -f "/usr/local/bin/tls-shunt-proxy" ]; then # tls-shunt-proxy not installed
      colorEcho ${BLUE} "tls-shunt-proxy not installed, start installation"
      curl -sSL https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/dist/install.sh | ${sudoCmd} bash
      colorEcho ${GREEN} "tls-shunt-proxy is installed."
      cd $(mktemp -d)
      # crate new config.yaml and overwrite whatever the current one exisits or not
      wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/config.yaml
      sed -i "s/##MTPROTO@//g" config.yaml
      sed -i "s/FAKEMTDOMAIN/${FAKE_TLS_HEADER}/g" config.yaml
      ${sudoCmd} /bin/cp -f config.yaml /etc/tls-shunt-proxy/config.yaml
    elif [ -f "/etc/tls-shunt-proxy/config.yaml" ]; then # tls-shunt-proxy installed and config.yaml exists
      ${sudoCmd} cat /etc/tls-shunt-proxy/config.yaml | ${sudoCmd} tee /etc/tls-shunt-proxy/config.yaml.bak
      cd $(mktemp -d)
      ${sudoCmd} cat /etc/tls-shunt-proxy/config.yaml | ${sudoCmd} tee config-new.yaml
      sed -i "s/##MTPROTO@//g" config-new.yaml
      sed -i "s/FAKEMTDOMAIN/${FAKE_TLS_HEADER}/g" config-new.yaml
      ${sudoCmd} /bin/cp -f config-new.yaml /etc/tls-shunt-proxy/config.yaml
    fi
    
    # activate service
    ${sudoCmd} systemctl enable docker
    ${sudoCmd} systemctl restart docker
    ${sudoCmd} systemctl enable tls-shunt-proxy
    ${sudoCmd} systemctl restart tls-shunt-proxy
    ${sudoCmd} systemctl daemon-reload
    
    colorEcho ${GREEN} "电报代理设置成功!"
    echo ""
    echo "tg://proxy?server=$(${sudoCmd} cat /usr/local/etc/v2script/tls-header)&port=443&secret=$(${sudoCmd} cat /usr/local/etc/v2script/mtproto-secret)"
  else
    echo "tg://proxy?server=$(${sudoCmd} cat /usr/local/etc/v2script/tls-header)&port=443&secret=$(${sudoCmd} cat /usr/local/etc/v2script/mtproto-secret)"
  fi
}

check_status() {
  printf "TCP+TLS+WEB状态: "
  if [ -d "/usr/bin/v2ray" ] && [ -f "/usr/local/bin/tls-shunt-proxy" ] && [ -f "/usr/local/etc/v2script/Caddyfile" ]; then
    colorEcho ${GREEN} "己安装"
  else
    colorEcho ${YELLOW} "未安装"
  fi

  printf "主订阅链接: "
  if [ -f "/usr/local/etc/v2script/subscription" ] && [ -f "/usr/local/etc/v2script/tls-header" ]; then
    colorEcho ${YELLO} "https://$(${sudoCmd} cat /usr/local/etc/v2script/tls-header)/$(${sudoCmd} cat /usr/local/etc/v2script/subscription)"
  else
    colorEcho ${YELLO} "尚未生成"
  fi

  printf "电报代理:　 "
  if [ ! -f "/usr/local/etc/v2script/mtproto-header" ] && [ ! -f "/usr/local/etc/v2script/mtproto-secret" ]; then
    colorEcho ${YELLOW} "tg://proxy?server=$(${sudoCmd} cat /usr/local/etc/v2script/tls-header)&port=443&secret=$(${sudoCmd} cat /usr/local/etc/v2script/mtproto-secret)"
  else
    colorEcho ${YELLOW} "未设置"
  fi

  echo ""
  printf "Swap状态:        "
  if [[ ! $(cat /proc/swaps | wc -l) -gt 1 ]]; then
    colorEcho ${GREEN} "己开启"
  else
    colorEcho ${YELLOW} "未开启"
  fi

  if [ -f /usr/sbin/aliyun-service ]; then
    echo ""
    colorEcho ${RED} "检测到阿里云监测服务 建议卸载"
  fi

  echo ""
}

vps_tools() {
  ${sudoCmd} ${systemPackage} install curl -y
  curl -sSL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/vps_tools.sh | bash
  exit 0
}

menu() {
  colorEcho ${YELLOW} "v2Ray TCP+TLS+WEB automated script v1.0"
  colorEcho ${YELLOW} "author: phlinhng"
  echo ""

  check_status

  PS3="选择操作[输入任意值或按Ctrl+C退出]: "
  COLUMNS=39
  options=("安装TCP+TLS+WEB" "更新v2Ray-core" "卸载TCP+TLS+WEB" "显示vmess链接" "管理订阅" "设置电报代理" "安装加速脚本" "设置Swap" "卸载阿里云盾")
  select opt in "${options[@]}"
  do
    case "${opt}" in
      "安装TCP+TLS+WEB") install_v2ray && continue_prompt ;;
      "更新v2Ray-core") get_v2ray && continue_prompt ;;
      "卸载TCP+TLS+WEB") rm_v2script ;;
      "显示vmess链接") display_vmess && continue_prompt ;;
      "管理订阅") get_v2sub && continue_prompt ;;
      "设置电报代理") install_mtproto && continue_prompt;;
      "VPS工具") vps_tools ;;
      *) break ;;
    esac
  done

}

menu
