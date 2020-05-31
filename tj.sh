#!/bin/bash

# lite version

export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

branch="master"

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

urlEncode() {
  printf %s "$1" | jq -s -R -r @uri
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

get_trojan() {
  colorEcho ${BLUE} "Getting the latest version of trojan-go"
  local latest_version="$(curl -s "https://api.github.com/repos/p4gefau1t/trojan-go/releases" | jq '.[0].tag_name' --raw-output)"
  echo "${latest_version}"
  local trojango_link="https://github.com/p4gefau1t/trojan-go/releases/download/${latest_version}/trojan-go-linux-amd64.zip"

  ${sudoCmd} mkdir -p "/usr/bin/trojan-go"
  ${sudoCmd} mkdir -p "/etc/trojan-go"
  ${sudoCmd} mkdir -p "/etc/ssl/trojan-go"

  wget -nv "${trojango_link}" -O trojan-go.zip
  unzip -q trojan-go.zip && rm -rf trojan-go.zip
  ${sudoCmd} mv trojan-go /usr/bin/trojan-go/trojan-go

  colorEcho ${BLUE} "Building trojan-go.service"
  ${sudoCmd} mv example/trojan-go.service /etc/systemd/system/trojan-go.service

  ${sudoCmd} wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/bin/trojan-go/geoip.dat
  ${sudoCmd} wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/bin/trojan-go/geosite.dat

  # set crontab to auto update geoip.dat and geosite.dat
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/bin/trojan-go/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/bin/trojan-go/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -

  colorEcho ${GREEN} "trojan-go is installed."
}

get_cert() {
  ${sudoCmd} trojan-go -autocert request
  ${sudoCmd} mv server.crt /etc/ssl/trojan-go/server.crt
  ${sudoCmd} mv server.key /etc/ssl/trojan-go/server.key
  ${sudoCmd} mv user.key /etc/ssl/trojan-go/user.key
  ${sudoCmd} mv domain_info.json /etc/ssl/trojan-go/domain_info.json

  (crontab -l 2>/dev/null; echo "5 4 3 * * systemctl stop trojan-go") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "5 4 3 * * cd /etc/ssl/trojan-go && trojan-go -autocert renew") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "5 4 3 * * systemctl restart trojan-go") | ${sudoCmd} crontab -
}

install_trojan() {
  while true; do
    read -rp "解析到本 VPS 的域名: " TJ_DOMAIN
    if checkIP "${TJ_DOMAIN}"; then
      colorEcho ${GREEN} "域名 ${TJ_DOMAIN} 解析正确, 即将开始安装"
      break
    else
      colorEcho ${RED} "域名 ${TJ_DOMAIN} 解析有误 (yes: 强制继续, no: 重新输入, quit: 离开)"
      read -rp "若您确定域名解析正确, 可以继续进行安装作业. 强制继续? (yes/no/quit) " forceConfirm
      case "${forceConfirm}" in
        [yY]|[yY][eE][sS] ) break ;;
        [qQ]|[qQ][uU][iI][tT] ) return 0 ;;
      esac
    fi
  done

  ${sudoCmd} ${systemPackage} update -qq
  ${sudoCmd} ${systemPackage} install curl wget jq unzip -y -qq

  cd "$(mktemp -d)"

  # install trojan-go
  get_trojan

  # apply for ssl certificates and set auto renew
  get_cert

  # create config files
  if [ ! -f "/etc/trojan-go/config.json" ]; then
    colorEcho ${BLUE} "Setting trojan-go"
    wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/trojan-go_standalone.json -O /tmp/trojan-go.json
    sed -i "s/FAKETROJANPWD/$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 12)/g" /tmp/trojan-go.json
    ${sudoCmd} /bin/cp -f /tmp/trojan-go.json /etc/trojan-go/config.json
  fi

  ${sudoCmd} systemctl enable trojan-go
  ${sudoCmd} systemctl restart trojan-go 2>/dev/null ## restart trojan-go to enable new config
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  colorEcho ${GREEN} "安装 trojan-go 成功!"

  local uuid_trojan="$(read_json /etc/trojan-go/config.json '.password[0]')"
  local uri_trojan="${uuid_trojan}@${TJ_DOMAIN}:443?peer=#$(urlEncode "${TJ_DOMAIN}")"

  printf '%s\n' "trojan://${uri_trojan}"
}

install_trojan
