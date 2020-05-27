read_json() {
  # jq [key] [path-to-file]
  ${sudoCmd} jq --raw-output $2 $1 2>/dev/null | tr -d '\n'
} ## read_json [path-to-file] [key]

set_v2ray_wss() {
    local ports=(2053 2083 2087 2096 8443)
    local port="${ports[RANDOM%5]}"
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    local wssPath="$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 12)"
    local sni="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"

    local cfUrl="amp.cloudflare.com"
    local currentRemark="$(read_json /usr/local/etc/v2script/config.json '.sub.nodes[0]' | sed 's/^vmess:\/\///g' | base64 -d | jq --raw-output '.ps' | tr -d '\n')"
    local json="{\"add\":\"${cfUrl}\",\"aid\":\"0\",\"host\":\"${sni}\",\"id\":\"${uuid}\",\"net\":\"ws\",\"path\":\"/${wssPath}\",\"port\":\"${port}\",\"ps\":\"${currentRemark} (CDN)\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    local uri="$(printf %s "${json}" | base64 | tr -d '\n')"

    # updating subscription
    if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.enabled') == "true" ]]; then
      local full="vmess://${uri}"
       write_json /usr/local/etc/v2script/config.json '.sub.nodes[0]' "$(printf "\"vmess://${uri}\"" | tr -d '\n')"
      local sub="$(printf %s "${full}" | base64 | tr -d '\n')"
      echo "${sub}" | ${sudoCmd} tee -a /var/www/html/$(read_json /usr/local/etc/v2script/config.json '.sub.uri') >/dev/null
    fi

    echo "${cfUrl}:${port}"
    echo "${uuid} (aid: 0)"
    echo "Header: ${sni}, Path: /${wssPath}" && echo ""
    echo "vmess://${uri}" | tr -d '\n' && printf "\n"
}

set_v2ray_wss