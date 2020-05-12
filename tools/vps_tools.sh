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
colorEcho(){
  echo -e "\033[${1}${@:2}\033[0m" 1>& 2
}

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

# a trick to redisplay menu option
show_menu() {
  echo ""
  echo "1) 安装加速"
  echo "2) 设置Swap"
  echo "3) 卸载阿里云盾"
  echo "4) 性能测试"
}

continue_prompt() {
  read -p "继续其他操作 (yes/no)? " choice
  case "${choice}" in
    y|Y|[yY][eE][sS] ) show_menu ;;
    * ) exit 0;;
  esac
}

netSpeed() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  wget -q -N https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh -O /tmp/tcp.sh && chmod +x /tmp/tcp.sh && ${sudoCmd} /tmp/tcp.sh
}

setSwap() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/tools/set_swap.sh | bash
}

rmAliyundun() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/master/tools/rm_aliyundun.sh | bash
}

# credit: https://github.com/LemonBench/LemonBench
LemonBench() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://raw.githubusercontent.com/LemonBench/LemonBench/master/LemonBench.sh | bash  -s -- --mode full
}

menu() {
  cd "$(dirname "$0")"
  colorEcho ${YELLOW} "VPS Toolkit by phlinhng"
  echo ""

  PS3="选择操作[输入任意值或按Ctrl+C退出]: "
  COLUMNS=39
  options=("安装加速" "设置Swap" "卸载阿里云盾" "性能测试")
  select opt in "${options[@]}"
  do
    case "${opt}" in
      "安装加速") netSpeed && continue_prompt;;
      "设置Swap") setSwap && continue_prompt ;;
      "卸载阿里云盾") rmAliyundun && continue_prompt ;;
      "性能测试") LemonBench && exit 0;;
      *) break;;
    esac
  done

}

menu