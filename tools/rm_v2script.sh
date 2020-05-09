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

if [ ! -d "/usr/bin/v2ray" ] || [ ! -f "/usr/local/bin/tls-shunt-proxy" ]; then
  return 1
fi

${sudoCmd} ${systemPackage} install curl -y

# remove v2ray
# Notice the two dashes (--) which are telling bash to not process anything following it as arguments to bash.
# https://stackoverflow.com/questions/4642915/passing-parameters-to-bash-when-executing-a-script-fetched-by-curl
curl -sSL https://install.direct/go.sh | ${sudoCmd} bash -s -- --remove
${sudoCmd} rm -rf /etc/v2ray
${sudoCmd} deluser v2ray

# remove tls-shunt-server
colorEcho ${BLUE} "Shutting down tls-shunt-proxy service."
${sudoCmd} systemctl stop tls-shunt-proxy
${sudoCmd} systemctl disable tls-shunt-proxy
${sudoCmd} rm -f /etc/systemd/system/tls-shunt-proxy.service
${sudoCmd} rm -f /etc/systemd/system/tls-shunt-proxy.service # and symlinks that might be related
${sudoCmd} systemctl daemon-reload
${sudoCmd} systemctl reset-failed
colorEcho ${BLUE} "Removing tls-shunt-proxy files."
${sudoCmd} rm -rf /usr/local/bin/tls-shunt-proxy
${sudoCmd} rm -rf /etc/ssl/tls-shunt-proxy
colorEcho ${BLUE} "Removing tls-shunt-proxy user & group."
${sudoCmd} deluser tls-shunt-proxy
${sudoCmd} delgroup --only-if-empty tls-shunt-proxy
colorEcho ${GREEN} "Removed tls-shunt-proxy successfully."

# docker
# this will stop docker.service and remove every conatainer, image...etc created by docker but not docker itself
# since uninstalling docker is complicated and may cause unstable to OS, if you want the OS to go back to clean state then reinstall the whole OS is suggested
colorEcho ${BLUE} "Shutting down docker service."
${sudoCmd} systemctl stop docker
${sudoCmd} systemctl disable docker
colorEcho ${BLUE} "Removing docker containers, images, networks, and images"
${sudoCmd} docker stop "$(docker ps -a -q)"
${sudoCmd} docker system prune --force
colorEcho ${GREEN} "Removed docker successfully."

# remove script configuration files
${sudoCmd} rm -rf /usr/local/etc/v2script
${sudoCmd} rm -f /usr/local/bin/v2script
${sudoCmd} rm -f /usr/local/bin/v2ssub

${sudoCmd} ${systemPackage} autoremove -y

colorEcho ${BLUE} "卸载完成"