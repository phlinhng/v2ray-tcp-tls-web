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

if [[ ! $(cat /proc/swaps | wc -l) -gt 1 ]]; then
  # allocate space
  # ${sudoCmd} fallocate -l 1G /swapfile
  ${sudoCmd} dd if=/dev/zero of=/swapfile bs=1024 count=1048576

  # set permission
  ${sudoCmd} chmod 600 /swapfile

  # make swap
  ${sudoCmd} mkswap /swapfile

  # enable swap
  ${sudoCmd} swapon /swapfile

  # make swap permanent
  echo "/swapfile swap swap defaults 0 0" | ${sudoCmd} tee -a /etc/fstab  >/dev/null

  # set swap percentage
  ${sudoCmd} sysctl vm.swappiness=10
  echo "vm.swappiness=10" | ${sudoCmd} tee -a /etc/sysctl.conf >/dev/null

  free -h
  colorEcho ${GREEN} "设置Swap成功"
else
  free -h
  colorEcho ${BLUE} "己有Swap 无需设置"
fi
