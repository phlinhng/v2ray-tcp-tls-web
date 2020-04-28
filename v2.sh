#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "请使用root用户或sudo指令執行"
    exit 2
fi

read -p "解析到本VPS的域名: " V2_DOMAIN

# install requirements
# uuid-runtime: for uuid generating
# coreutils: for base64 command
# nginx: for redirecting http to https to make dummy site look more real
apt-get install curl git uuid-runtime coreutils wget nginx -y

# install v2ray
bash <(curl -L -s https://install.direct/go.sh)

# install tls-shunt-proxy
bash <(curl -L -s https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/dist/install.sh)

rm -rf v2ray-tcp-tls-web
git clone https://github.com/phlinhng/v2ray-tcp-tls-web.git
cd v2ray-tcp-tls-web

# create config files
uuid=$(uuidgen)
sed -i "s/FAKEUUID/${uuid}/g" config.json
sed -i "s/FAKEDOMAIN/${V2_DOMAIN}/g" config.yaml
sed -i "s/FAKEDOMAIN/${V2_DOMAIN}/g" default

# copy cofig files to respective path
/bin/cp -f config.json /etc/v2ray
/bin/cp -f config.yaml /etc/tls-shunt-proxy
/bin/cp -f default /etc/nginx/sites-available

# copy template for dummy web pages
mkdir -p /var/www/html
/bin/cp -f templated-industrious/. /var/www/html

# set crontab to auto update geoip.dat and geosite.dat
(crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat -O /usr/bin/v2ray/geoip.dat >/dev/null >/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat -O /usr/bin/v2ray/geosite.dat >/dev/null >/dev/null") | crontab -

# activate services
systemctl daemon-reload
systemctl enable ntp
systemctl start ntp
systemctl enable v2ray
systemctl start v2ray
systemctl enable tls-shunt-proxy
systemctl start tls-shunt-proxy
systemctl enable nginx
systemctl restart nginx

# remove installation files
cd ..
rm -rf v2ray-caddy-cf

echo ""
echo "${V2_DOMAIN}:443"
echo "${uuid} (aid: 0)"
echo ""

json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${V2_DOMAIN}:443\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"

uri="$(echo "${json}" | base64)"
printf "vmess://${uri}"

exit 0







