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

# remove v2ray
# Notice the two dashes (--) which are telling bash to not process anything following it as arguments to bash.
# https://stackoverflow.com/questions/4642915/passing-parameters-to-bash-when-executing-a-script-fetched-by-curl
curl -sL https://install.direct/go.sh | ${sudoCmd} bash -s -- --remove
colorEcho ${BLUE} "Shutting down v2ray service."
${sudoCmd} systemctl stop v2ray
${sudoCmd} systemctl disable v2ray
${sudoCmd} $(which rm) -f /etc/systemd/system/v2ray.service
${sudoCmd} $(which rm) -f /etc/systemd/system/v2ray.service
${sudoCmd} $(which rm) -f /etc/systemd/system/v2ray@.service
${sudoCmd} $(which rm) -f /etc/systemd/system/v2ray@.service
colorEcho ${BLUE} "Removing v2ray files."
${sudoCmd} $(which rm) -rf /etc/v2ray
${sudoCmd} $(which rm) -rf /usr/bin/v2ray
${sudoCmd} $(which rm) -rf /usr/local/bin/v2ray
${sudoCmd} $(which rm) -rf /usr/local/bin/v2ctl
${sudoCmd} $(which rm) -rf /usr/local/etc/v2ray
${sudoCmd} $(which rm) -rf /usr/local/lib/v2ray
${sudoCmd} $(which rm) -rf /usr/local/share/v2ray
${sudoCmd} $(which rm) -rf /var/log/v2ray
${sudoCmd} $(which rm) -rf /tmp/v2ray-ds
colorEcho ${BLUE} "Removing v2ray user & group."
${sudoCmd} deluser v2ray
${sudoCmd} delgroup --only-if-empty v2ray
colorEcho ${BLUE} "Removing v2ray crontab"
${sudoCmd} crontab -l | grep -v 'v2ray/geoip.dat' | ${sudoCmd} crontab -
${sudoCmd} crontab -l | grep -v 'v2ray/geosite.dat' | ${sudoCmd} crontab -
colorEcho ${GREEN} "Removed v2ray successfully."

# remove caddy
colorEcho ${BLUE} "Shutting down nginx service."
${sudoCmd} systemctl stop nginx
${sudoCmd} systemctl disable nginx
${sudoCmd} $(which rm) -f /etc/systemd/system/nginx.service
${sudoCmd} $(which rm) -f /etc/systemd/system/nginx.service # and symlinks that might be related
${sudoCmd} systemctl daemon-reload
${sudoCmd} systemctl reset-failed
colorEcho ${BLUE} "Removing nginx"
${sudoCmd} ${systemPackage} remove nginx -y
colorEcho ${GREEN} "Removed nginx successfully."

colorEcho ${BLUE} "Removing dummy site."
${sudoCmd} $(which rm) -rf /var/www/html

# remove trojan-go
colorEcho ${BLUE} "Shutting down trojan-go service."
${sudoCmd} systemctl stop trojan-go
${sudoCmd} systemctl disable trojan-go
${sudoCmd} $(which rm) -f /etc/systemd/system/trojan-go.service
${sudoCmd} $(which rm) -f /etc/systemd/system/trojan-go.service # and symlinks that might be related
${sudoCmd} systemctl daemon-reload
${sudoCmd} systemctl reset-failed
colorEcho ${BLUE} "Removing trojan-go files."
${sudoCmd} $(which rm) -rf /usr/bin/trojan-go
${sudoCmd} $(which rm) -rf /etc/trojan-go
colorEcho ${GREEN} "Removed trojan-go successfully."

colorEcho ${BLUE} "Removing acme.sh"
${sudoCmd} bash ~/.acme.sh/acme.sh --uninstall
${sudoCmd} $(which rm) -f ~/.acme.sh
colorEcho ${GREEN} "Removed acme.sh successfully."

${sudoCmd} ${systemPackage} autoremove -y --purge

colorEcho ${BLUE} "卸载完成"
