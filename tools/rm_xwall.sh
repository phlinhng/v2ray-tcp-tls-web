#!/bin/bash
export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

if [[ "$(command -v apt)" ]]; then
  PACKAGE_MANAGEMENT_UPDATE='apt update'
  PACKAGE_MANAGEMENT_INSTALL='apt install'
  PACKAGE_MANAGEMENT_REMOVE='apt remove'
elif [[ "$(command -v yum)" ]]; then
  PACKAGE_MANAGEMENT_UPDATE='yum update'
  PACKAGE_MANAGEMENT_INSTALL='yum install'
  PACKAGE_MANAGEMENT_REMOVE='yum remove'
elif [[ "$(command -v dnf)" ]]; then
  PACKAGE_MANAGEMENT_UPDATE='dnf update'
  PACKAGE_MANAGEMENT_INSTALL='dnf install'
  PACKAGE_MANAGEMENT_REMOVE='dnf remove'
elif [[ "$(command -v zypper)" ]]; then
  PACKAGE_MANAGEMENT_INSTALL='zypper install'
  PACKAGE_MANAGEMENT_REMOVE='zypper remove'
elif [[ "$(command -v pacman)" ]]; then
  PACKAGE_MANAGEMENT_INSTALL='pacman -S'
  PACKAGE_MANAGEMENT_REMOVE='pacman -R'
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

uninstall() {
  ${sudoCmd} $(which rm) -rf $1
  printf "Removed: %s\n" $1
}

# remove xray
if [ -f "/usr/local/bin/xray" ]; then
  colorEcho ${BLUE} "Stopping xray service."
  ${sudoCmd} systemctl stop xray
  ${sudoCmd} systemctl disable xray
  uninstall "/etc/systemd/system/xray.service"
  colorEcho ${BLUE} "Removing xray binaries."
  uninstall "/usr/local/bin/xray"
  colorEcho ${BLUE} "Removing xray files."
  uninstall "/usr/local/etc/xray"
  uninstall"/usr/local/share/xray"
  uninstall "/var/log/xray"
  colorEcho ${BLUE} "Removing xray crontab."
  ${sudoCmd} crontab -l | grep -v 'xray/geoip.dat' | ${sudoCmd} crontab -
  ${sudoCmd} crontab -l | grep -v 'xray/geosite.dat' | ${sudoCmd} crontab -
  colorEcho ${GREEN} "Removed xray successfully."
fi

# remove trojan-go
if [ -f "/usr/bin/trojan-go" ]; then
  colorEcho ${BLUE} "Shutting down trojan-go service."
  ${sudoCmd} systemctl stop trojan-go
  ${sudoCmd} systemctl disable trojan-go
  uninstall /etc/systemd/system/trojan-go.service
  colorEcho ${BLUE} "Removing trojan-go binaries."
  uninstall /usr/bin/trojan-go
  colorEcho ${BLUE} "Removing trojan-go files."
  uninstall /usr/bin/geoip.dat
  uninstall /usr/bin/geosite.dat
  uninstall /etc/trojan-go
  colorEcho ${GREEN} "Removed trojan-go successfully."
fi

colorEcho ${BLUE} "Removing dummy site."
${sudoCmd} $(which rm) -rf /var/www/acme
${sudoCmd} $(which rm) -rf /var/www/html/*

# remove cerbot
if [ -d "etc/letsencrypt" ]; then
  colorEcho ${BLUE} "Removing certbot"
  ${sudoCmd} ${PACKAGE_MANAGEMENT_REMOVE} certbot -y
  uninstall /etc/letsencrypt
  ${sudoCmd} crontab -l | grep -v 'certbot' | ${sudoCmd} crontab -
  colorEcho ${GREEN} "Removed acme.sh successfully."
fi

colorEcho ${BLUE} "卸载完成"