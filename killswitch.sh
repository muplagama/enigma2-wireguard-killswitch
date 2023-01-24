#!/bin/bash
### Save default route ###
if [ ! -f /etc/wireguard/route_default ]; then
   ip route show default | grep default > /etc/wireguard/route_default
fi
### Grep VPN url ###
url_grep=$(cat /etc/wireguard/wg0.conf | grep Endpoint | awk -F'=' '{print $2}' | awk -F# '{gsub(/ /,"");print ($1) }' |awk -F ':' '{print $1}')

### Sets ###
dns_ip=1.1.1.1
route_default=$(cat /etc/wireguard/route_default | grep default)
route_ip=$(cat /etc/wireguard/route_default | awk '/default/ {print $3}')
route_dev=$(cat /etc/wireguard/route_default | awk '/default/ {print $5}')

while true
do
### wg interface check
        check_vpn=$(wg show | grep endpoint)
                if  [ ! -z "$check_vpn" ]
                then
### add default route
        add_default=$(ip route show default | grep default)
                if  [ -z "$add_default" ]
                then
                ip route add $route_default
                fi
### check wg ping
        ping_check=$(ping -c 2 -I wg0 1.1.1.1 | grep time)
                if  [ ! -z "$ping_check" ]
                then
### lookup srv ip
        dns_v4=$(nslookup -query=A $url_grep 1.1.1.1 | grep Address | sed '/:53$/d' | sed s/^[^0-9]*//)
        rem_backup_v4=$(ip route show | grep "$dns_v4" )
                if  [ ! -z "$rem_backup_v4" ]
                then
                ip route del $dns_v4
                fi
                else
                echo "Ping not  OK"
                wg-quick down wg0 > /dev/null 2>&1
                wg-quick up wg0
                fi
         else
### remove default route
        del_default=$(ip route show default | grep default)
                if  [ ! -z "$del_default" ]
                then
                ip route del default
                fi

### DNS Request
        dns_request=$(ip route show | grep "default")
                if  [ -z "$dns_request" ]
                then
                ip route add $dns_ip via $route_ip dev $route_dev
                sleep 1
        dns_v4=$(nslookup -query=A $url_grep 1.1.1.1 | grep Address | sed '/:53$/d' | sed s/^[^0-9]*//)
                ip route del $dns_ip
                fi
### add Backup Route
        add_backup_A=$(ip route show | grep "$dns_v4")
                if  [ -z "$add_backup_A" ]
                then
                ip route add $dns_v4 via $route_ip dev $route_dev
                fi
                wg-quick down wg0 > /dev/null 2>&1
                wg-quick up wg0
                sleep 3
                fi

done
