#!/bin/bash

ip4_api="--ipv4 https://v4.ident.me/"
ip6_api="--ipv6 https://v6.ident.me/"

checkIP() {
  local realIP4="$(curl -s ${ip4_api} -m 5)"
  local resolvedIP4="$(curl https://cloudflare-dns.com/dns-query\?name\=$1\&type\=A -sSL -H 'accept: application/dns-json' | jq ".Answer[0].data" --raw-output)"

  if [[ "${realIP4}" == "${resolvedIP4}" ]]; then
    return 0
  else
    local realIP6="$(curl -s ${ip6_api} -m 5)"
    local resolvedIP6="$(curl https://cloudflare-dns.com/dns-query\?name\=$1\&type\=AAAA -sSL -H 'accept: application/dns-json' | jq ".Answer[0].data" --raw-output)"
    if [[ "${realIP6}" == "${resolvedIP6}" ]]; then
      echo "ipv6 check success"
      return 0
    else
      return 1
    fi
  fi
}

checkIP $1 && echo "success"

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

red="\033[0;${RED}"
green="\033[0;${GREEN}"
blue="\033[0;${BLUE}"
nocolor="\033[0m"

colorEcho $BLUE "测试1\r"
colorEcho $BLUE "测试1完成"
colorEcho $YELLOW "测试2\r"
colorEcho $GREEN "测试2完成"
