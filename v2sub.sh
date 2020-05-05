#!/bin/bash

# /usr/local/etc/v2script ##config path
# /usr/local/etc/v2script/tls-header ##domain for v2Ray
# /usr/local/etc/v2script/subscription ##filename of main subscription

# /usr/local/bin/v2script ##main
# /usr/local/bin/v2sub ##subscription manager

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
  echo "1) 生成订阅"
  echo "2) 更新订阅"
}

continue_prompt() {
  read -p "继续其他操作 (yes/no)? " choice
  case "${choice}" in
    y|Y|[yY][eE][sS] ) show_menu ;;
    * ) exit 0;;
  esac
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
  V2_DOMAIN=$(${sudoCmd} cat /usr/local/etc/v2script/tls-header | tr -d '\n')

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

menu() {
  colorEcho ${YELLOW} "v2Ray TCP+TLS+WEB subscription manager v0.3.1"
  colorEcho ${YELLOW} "author: phlinhng"
  echo ""

  PS3="选择操作[输入任意值或按Ctrl+C退出]: "
  COLUMNS=39
  options=("生成订阅" "更新订阅")
  select opt in "${options[@]}"
  do
    case "${opt}" in
      "生成订阅") generate_link && continue_prompt ;;
      "更新订阅") update_link && continue_prompt ;;
      *) break;;
    esac
  done

}

menu