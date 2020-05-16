#!/bin/bash
export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8

branch="master"

# /usr/local/etc/v2script/config.json ##config path

# /usr/local/bin/v2script ##main
# /usr/local/bin/v2sub ##subscription manager

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

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

# install requirements
#${sudoCmd} ${systemPackage} update
${sudoCmd} ${systemPackage} install curl wget jq -y -qq

mkdir -p /usr/local/etc/v2script

if [ ! -f "/usr/local/etc/v2script/config.json" ]; then
  wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/v2script.json -O /usr/local/etc/v2script/config.json
fi

wget -q -N https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/src/v2script.sh -O /usr/local/bin/v2script
chmod +x /usr/local/bin/v2script

wget -q -N https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/src/v2sub.sh -O /usr/local/bin/v2sub
chmod +x /usr/local/bin/v2sub

