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

if [ ! -f /usr/sbin/aliyun-service ]; then
  colorEcho ${YELLOW} "未检测到阿里云相关服务"
  exit 1
else
  # https://zhuanlan.zhihu.com/p/52758924

  ${sudoCmd} ${systemPackage} install wget -y

  cd $(mktemp -d)

  colorEcho ${BLUE} "卸载阿里云盾..."
  ${sudoCmd} wget http://update.aegis.aliyun.com/download/uninstall.sh
  ${sudoCmd} chmod +x uninstall.sh && ${sudoCmd} ./uninstall.sh
  ${sudoCmd} wget http://update.aegis.aliyun.com/download/quartz_uninstall.sh
  ${sudoCmd} chmod +x quartz_uninstall.sh && ${sudoCmd} ./quartz_uninstall.sh

  colorEcho ${BLUE} "删除阿里云盾文件残留..."
  ${sudoCmd} pkill aliyun-service
  ${sudoCmd} rm -rf /etc/init.d/agentwatch /usr/sbin/aliyun-service
  ${sudoCmd} rm -rf /usr/local/aegis*

  colorEcho ${BLUE} "卸载云监控Java版本插件..."
  ${sudoCmd} /usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh stop
  ${sudoCmd} /usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh remove
  ${sudoCmd} rm -rf /usr/local/cloudmonitor

  colorEcho ${BLUE} "屏蔽阿里云盾IP..."
  ${sudoCmd} iptables -I INPUT -s 140.205.201.0/28 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.201.16/29 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.201.32/28 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.225.192/29 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.225.200/30 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.225.184/29 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.225.183/32 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.225.206/32 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.225.205/32 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.225.195/32 -j DROP
  ${sudoCmd} iptables -I INPUT -s 140.205.225.204/32 -j DROP

  colorEcho ${GREEN} "阿里云盾己卸载"

  exit 0
fi