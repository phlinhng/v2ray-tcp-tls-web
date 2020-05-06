#!/bin/bash

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
elif cat /etc/issue | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
fi

# copied from v2ray official script
# colour code
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message
# colour function
colorEcho() {
  echo -e "\033[${1}${@:2}\033[0m" 1>& 2
}

if [[ ! $(cat /proc/swaps | wc -l) -gt 1 ]]; then
  # allocate space
  ${sudoCmd} fallocate -l 1G /swapfile

  # set permission
  ${sudoCmd} chmod 600 /swapfile

  # make swap
  ${sudoCmd} mkswap /swapfile

  # enable swap
  ${sudoCmd} swapon /swapfile

  # make swap permanent
  printf "/swapfile swap swap defaults 0 0" | ${sudoCmd} tee -a /etc/fstab  >/dev/null

  # set swap percentage
  ${sudoCmd} sysctl vm.swappiness=10
  printf "vm.swappiness=10" | ${sudoCmd} tee -a /etc/sysctl.conf >/dev/null

  free -h
  colorEcho ${GREEN} "设置Swap成功"
  return 0
else
  free -h
  colorEcho ${BLUE} "己有Swap 无需设置"
  return 0
fi