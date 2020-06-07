#!/bin/bash
export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

branch="dev"

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

read_json() {
  # jq [key] [path-to-file]
  ${sudoCmd} jq --raw-output $2 $1 2>/dev/null | tr -d '\n'
} ## read_json [path-to-file] [key]

if [[ $(read_json /usr/local/etc/v2script/config.json '.trojan.installed') == "true" ]] && [[ $(read_json /etc/trojan-go/config.json '.ssl.serve_plain_text') == "true" ]]; then
  echo -e "\033[0;33mMigrating trojan-go v0.5 config to new config\033[0m"

  ${sudoCmd} rm -f /etc/ssl/trojan-go/server*
  ${sudoCmd} cp /etc/trojan-go/config.json /etc/trojan-go/config.json.bak

  local currentPassword="$(read_json "/etc/trojan-go/config.json.bak" ".password[0]")"
  wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/trojan-go_plain.json -O /tmp/trojan-go.json
  sed -i "s/FAKETROJANPWD/"${currentPassword}"/g" /tmp/trojan-go.json
  ${sudoCmd} /bin/cp -f /tmp/trojan-go.json /etc/trojan-go/config.json

  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl restart trojan-go 2>/dev/null
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed
fi