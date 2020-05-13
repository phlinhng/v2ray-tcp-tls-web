#!/bin/bash
export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8

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
colorEcho() {
  echo -e "\033[${1}${@:2}\033[0m" 1>& 2
}

if [[ ! $(lsmod | grep bbr) ]]; then
  ${sudoCmd} modprobe tcp_bbr
  echo "tcp_bbr" | ${sudoCmd} tee -a /etc/modules-load.d/modules.conf >/dev/null
  echo "net.core.default_qdisc=cake" | ${sudoCmd} tee -a /etc/sysctl.conf >/dev/null
  echo "net.ipv4.tcp_congestion_control=bbr" | ${sudoCmd} tee -a /etc/sysctl.conf >/dev/null
  ${sudoCmd} sysctl -p
  colorEcho ${GREEN} "原版BBR己开启"
else
  ${sudoCmd} sysctl -p
  colorEcho ${BLUE} "原版BBR己开启"
fi
