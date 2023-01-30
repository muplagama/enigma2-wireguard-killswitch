#!/bin/bash
### Save default route ###
save_default=$(grep default /etc/wireguard/route_default | grep default )
        if  [ -z "$save_default" ]
        then
        ip route show default | grep default > /etc/wireguard/route_default
        else
        echo "default already set"
        fi

### Grep VPN url ###
url_grep=$(grep Endpoint /etc/wireguard/wg0.conf | awk -F'=' '{print $2}' | awk -F# '{gsub(/ /,"");print ($1) }' | awk -F ':' '{print $1}')

### Sets ###
dns_ip=1.1.1.1
route_default=$(grep default /etc/wireguard/route_default | grep default)
route_ip=$(grep default /etc/wireguard/route_default | awk '/default/ {print $3}')
route_dev=$(grep default /etc/wireguard/route_default | awk '/default/ {print $5}')

while true
do
### wg interface check
        check_vpn=$(wg show | grep endpoint)
                if  [ -n "$check_vpn" ]
                then
### add default route
        add_default=$(ip route show default | grep default)
                if  [ -z "$add_default" ]
                then
                ip route add default via "$route_ip" dev "$route_dev"
                fi
### check wg ping
        ping_check=$(ping -c 2 -I wg0 "$dns_ip" | grep time)
                if  [ -n "$ping_check" ]
                then
### lookup srv ip
        dns_v4=$(nslookup -query=A "$url_grep" "$dns_ip" | grep Address | sed '/:53$/d' | sed s/^[^0-9]*//)
        rem_backup_v4=$(ip route show | grep "$dns_v4" )
                if  [ -n "$rem_backup_v4" ]
                then
                ip route del "$dns_v4"
                fi
                else
                echo "Ping not  OK"
                wg-quick down wg0 > /dev/null 2>&1
                wg-quick up wg0
                fi
         else
### remove default route
        del_default=$(ip route show default | grep default)
                if  [ -n "$del_default" ]
                then
                ip route del default
                fi

### DNS Request
	ns_request=$(ip route show | grep "default")
                if  [ -z "$dns_request" ]
                then
                        ip route add "$dns_ip" via "$route_ip" dev "$route_dev"
                        sleep 1
                fi

                if [[ $url_grep =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
                then
                        dns_v4=$(grep Endpoint /etc/wireguard/wg0.conf | awk -F'=' '{print $2}' | awk -F# '{gsub(/ /,"");print ($1) }' | awk -F ':' '{print $1}')
                        ip route del "$dns_ip"
                else
                        dns_v4=$(nslookup -query=A "$url_grep" "$dns_ip" | grep Address | sed '/:53$/d' | sed s/^[^0-9]*//)
                        ip route del "$dns_ip"
                fi
### add Backup Route
        add_backup_A=$(ip route show | grep "$dns_v4")
                if  [ -z "$add_backup_A" ]
                then
                ip route add "$dns_v4" via "$route_ip" dev "$route_dev"
                fi
                wg-quick down wg0 > /dev/null 2>&1
                wg-quick up wg0
                sleep 3
                fi

done

