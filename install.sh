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
${sudoComm} ${systemPackage} update
${sudoComm} ${systemPackage} install curl wget git -y

wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/beta/v2script.sh -O /usr/local/bin/v2script
chmod +x /usr/local/bin/v2script && /usr/local/bin/v2script

exit 0

