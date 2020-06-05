#!/bin/bash
#=================================================
# Description: DIY script
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#=================================================
# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate
# sed -i 's/192.168.1.1/192.168.1.251/g'           package/base-files/files/bin/config_generate
sed -i '/static *)/,/lan *)/{0,//b;//s/"[^"]*"/"192.168.1.254"/}' package/base-files/files/bin/config_generate
grep -qP '^net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf || sed -i '1 a\net.netfilter.nf_conntrack_max=65535 ' package/base-files/files/etc/sysctl.conf
#set root pwd as ''
sed -i 's/^root:[^:]*:/root:$1$SywMFoHP$SXVOQ9JQLDUN37L2l3HOe.:/' package/base-files/files/etc/shadow

#modify feeds.conf.default add helloword project(ssr+)
grep -qP '^src-git helloworld' ./feeds.conf.default || echo "src-git helloworld https://github.com/fw876/helloworld" >> ./feeds.conf.default
./scripts/feeds update -a && ./scripts/feeds install -a


sed -i '/query_method=/s/tcp_only/udp_tcp/'      feeds/helloworld/luci-app-ssr-plus/root/etc/init.d/shadowsocksr

custom1=`cat <<-'EOF'
#custom1 modify\\
#127.0.0.1:7055:1081@1.0.0.1:853\\
echo "$dnsstr" |grep '@' && custom_socks5port=$(echo "$dnsstr" | awk -F '@' '{print $1}' |awk -F ':' '{print $3}') || custom_socks5port=$(echo "$dnsstr" |awk -F ':' '{print $3}')\\
custom_dns=$(echo "$dnsstr" | awk -F '@' '{print $2}')
EOF
`

custom2=`cat <<-'EOF'
#custom2 modify\\
custom_socks5port=${custom_socks5port:=1081}\\
custom_dns=${custom_dns:=8.8.4.4}\\
netstat -tupln |grep -q $custom_socks5port && (dns2socks 127.0.0.1:$custom_socks5port $custom_dns 127.0.0.1:7055 >/root/dns.log 2>&1 &) || echo 'Nomatch this socks5 port!' >/root/dns.log
EOF
`

custom3=`cat <<-'EOF'
#custom3 modify\\
# killall -q -9 trojan\\
ps -ef |grep trojan-ssr-retcp |grep -v grep |awk '$0=$1' |xargs kill -9\\
kill -9 $(busybox ps -w | grep trojan-ssr-socksdns | grep -v grep | awk '{print $1}') >/dev/null 2>&1\\
kill -9 $(busybox ps -w | grep trojan-ssr-netflix | grep -v grep | awk '{print $1}') >/dev/null 2>&1\\
kill -9 $(busybox ps -w | grep redsocks-ssr-retcp | grep -v grep | awk '{print $1}') >/dev/null 2>&1
EOF
`


sed -i -e '/local dnsport/{a\'"$custom1"' ' -e'}' feeds/helloworld/luci-app-ssr-plus/root/etc/init.d/shadowsocksr


sed -i -e '/start() /{
:a
/{/{x;s/^/./;x}
/}/{x;s/.//;/./!{x;i\'"$custom2"' ' -e';b};x}
n
ba
}' feeds/helloworld/luci-app-ssr-plus/root/etc/init.d/shadowsocksr


sed -i -e '/killall.*trojan/{c\'"$custom3"' ' -e'}' feeds/helloworld/luci-app-ssr-plus/root/etc/init.d/shadowsocksr

#disable subscribe.lua in crontab
sed -i 'N;\#sleep.*\n/usr/bin/lua.*shadowsocksr.*subscribe.lua$#d;P;D;' feeds/helloworld/luci-app-ssr-plus/root/usr/share/shadowsocksr/ssrplusupdate.sh
