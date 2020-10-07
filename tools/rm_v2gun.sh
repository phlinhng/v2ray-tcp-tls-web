#!/bin/bash
export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8

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

uninstall() {
  ${sudoCmd} $(which rm) -rf $1
  printf "Removed: %s\n" $1
}

# remove v2ray
colorEcho ${BLUE} "Stopping v2ray service."
${sudoCmd} systemctl stop v2ray
${sudoCmd} systemctl stop disable
uninstall "/etc/systemd/system/v2ray.service"
colorEcho ${BLUE} "Removing v2ray binaries."
uninstall "/usr/local/bin/v2ray"
uninstall "/usr/local/bin/v2ctl"
colorEcho ${BLUE} "Removing v2ray files."
uninstall "/usr/local/etc/v2ray"
uninstall"/usr/local/share/v2ray"
uninstall "/var/log/v2ray"
colorEcho ${BLUE} "Removing v2ray crontab."
${sudoCmd} crontab -l | grep -v 'v2ray/geoip.dat' | ${sudoCmd} crontab -
${sudoCmd} crontab -l | grep -v 'v2ray/geosite.dat' | ${sudoCmd} crontab -
colorEcho ${GREEN} "Removed v2ray successfully."

# remove nginx
colorEcho ${BLUE} "Shutting down nginx service."
${sudoCmd} systemctl stop nginx
${sudoCmd} systemctl disable nginx
uninstall /etc/systemd/system/nginx.service
colorEcho ${BLUE} "Removing nginx"
${sudoCmd} ${systemPackage} remove nginx -y
${sudoCmd} ${systemPackage} remove nginx-full -y
if [ -d "/usr/local/nginx" ]; then
  uninstall /usr/local/nginx
fi
colorEcho ${GREEN} "Removed nginx successfully."

colorEcho ${BLUE} "Removing dummy site."
${sudoCmd} $(which rm) -rf /var/www/html

# remove acme.sh
colorEcho ${BLUE} "Removing acme.sh"
${sudoCmd} bash /root/.acme.sh/acme.sh --uninstall
${sudoCmd} $(which rm) -rf /root/.acme.sh
colorEcho ${GREEN} "Removed acme.sh successfully."

${sudoCmd} ${systemPackage} autoremove -y --purge 2>/dev/null

colorEcho ${BLUE} "卸载完成"