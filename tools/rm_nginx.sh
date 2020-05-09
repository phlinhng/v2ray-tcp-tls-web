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

# remove nginx
# https://askubuntu.com/questions/361902/how-to-install-nginx-after-removed-it-manually
colorEcho ${BLUE} "Shutting down nginx service."
${sudoCmd} systemctl stop nginx
${sudoCmd} systemctl disable nginx
${sudoCmd} rm -f /etc/systemd/system/nginx.service
${sudoCmd} rm -f /etc/systemd/system/nginx.service # and symlinks that might be related
${sudoCmd} rm -f /lib/systemd/system/nginx.service
${sudoCmd} rm -f /lib/systemd/system/nginx.service # and symlinks that might be related
${sudoCmd} systemctl daemon-reload
${sudoCmd} systemctl reset-failed
colorEcho ${BLUE} "Purging nginx and dependencies."
${sudoCmd} ${systemPackage} autoremove nginx -y
${sudoCmd} ${systemPackage} --purge remove nginx
${sudoCmd} ${systemPackage} autoremove -y && ${sudoCmd} ${systemPackage} autoclean -y
colorEcho ${BLUE} "Removing nginx files."
${sudoCmd} find / | grep nginx | ${sudoCmd} xargs rm -rf
colorEcho ${GREEN} "Removed nginx successfully."