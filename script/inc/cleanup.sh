#!/bin/bash

_clean_custom_iptables() {
   # drop
   if [[ "$DROP_OUTBOUND_EN" == "yes" ]]; then
      RM_DROP_OUTBOUND_CMD=$(format_drop_iptable_rule "$WIFI_IFACE" "$DASH_DELETE")
      echo "${RM_DROP_OUTBOUND_CMD[@]}" >&2;
      ${RM_DROP_OUTBOUND_CMD[@]};
   fi

   clear_delay_rules "$WIFI_IFACE";
}

_cleanup() {
   local PID x

   trap "" SIGINT SIGUSR1 SIGUSR2 EXIT
   mutex_lock
   disown -a

   # kill haveged_watchdog
   [[ -n "$HAVEGED_WATCHDOG_PID" ]] && kill $HAVEGED_WATCHDOG_PID

   # kill processes
   for x in $CONFDIR/*.pid; do
      # even if the $CONFDIR is empty, the for loop will assign
      # a value in $x. so we need to check if the value is a file
      [[ -f $x ]] && kill -9 $(cat $x)
   done

   rm -rf $CONFDIR

   local found=0
   for x in $(list_running_conf); do
      if [[ -f $x/nat_internet_iface && $(cat $x/nat_internet_iface) == $INTERNET_IFACE ]]; then
         found=1
         break
      fi
   done

   if [[ $found -eq 0 ]]; then
      cp -f $COMMON_CONFDIR/${INTERNET_IFACE}_forwarding \
          /proc/sys/net/ipv4/conf/$INTERNET_IFACE/forwarding
      rm -f $COMMON_CONFDIR/${INTERNET_IFACE}_forwarding
   fi

   # if we are the last create_ap instance then set back the common values
   if ! has_running_instance; then
      # kill common processes
      for x in $COMMON_CONFDIR/*.pid; do
         [[ -f $x ]] && kill -9 $(cat $x)
      done

      # set old ip_forward
      if [[ -f $COMMON_CONFDIR/ip_forward ]]; then
         cp -f $COMMON_CONFDIR/ip_forward /proc/sys/net/ipv4
         rm -f $COMMON_CONFDIR/ip_forward
      fi

      # set old bridge-nf-call-iptables
      if [[ -f $COMMON_CONFDIR/bridge-nf-call-iptables ]]; then
         if [[ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]]; then
         cp -f $COMMON_CONFDIR/bridge-nf-call-iptables /proc/sys/net/bridge
         fi
         rm -f $COMMON_CONFDIR/bridge-nf-call-iptables
      fi

      rm -rf $COMMON_CONFDIR
   fi

   if [[ "$SHARE_METHOD" != "none" ]]; then
      if [[ "$SHARE_METHOD" == "nat" ]]; then
         echo "\n\nTEST1234\n\n";
         iptables -w -t nat -D POSTROUTING -s ${GATEWAY%.*}.0/24 ! -o ${WIFI_IFACE} -j MASQUERADE || die
         iptables -w -D FORWARD -i ${WIFI_IFACE} -s ${GATEWAY%.*}.0/24 -j ACCEPT
         iptables -w -D FORWARD -i ${INTERNET_IFACE} -d ${GATEWAY%.*}.0/24 -j ACCEPT
      elif [[ "$SHARE_METHOD" == "bridge" ]]; then
         if ! is_bridge_interface $INTERNET_IFACE; then
         ip link set dev $BRIDGE_IFACE down
         ip link set dev $INTERNET_IFACE down
         ip link set dev $INTERNET_IFACE promisc off
         ip link set dev $INTERNET_IFACE nomaster
         ip link delete $BRIDGE_IFACE type bridge
         ip addr flush $INTERNET_IFACE
         ip link set dev $INTERNET_IFACE up
         dealloc_iface $BRIDGE_IFACE

         for x in "${IP_ADDRS[@]}"; do
            x="${x/inet/}"
            x="${x/secondary/}"
            x="${x/dynamic/}"
            x=$(echo $x | sed 's/\([0-9]\)sec/\1/g')
            x="${x/${INTERNET_IFACE}/}"
            ip addr add $x dev $INTERNET_IFACE
         done

         ip route flush dev $INTERNET_IFACE

         for x in "${ROUTE_ADDRS[@]}"; do
            [[ -z "$x" ]] && continue
            [[ "$x" == default* ]] && continue
            ip route add $x dev $INTERNET_IFACE
         done

         for x in "${ROUTE_ADDRS[@]}"; do
            [[ -z "$x" ]] && continue
            [[ "$x" != default* ]] && continue
            ip route add $x dev $INTERNET_IFACE
         done

         networkmanager_rm_unmanaged_if_needed $INTERNET_IFACE
         fi
      fi
   fi

   if [[ "$SHARE_METHOD" != "bridge" ]]; then
      if [[ $NO_DNS -eq 0 ]]; then
         iptables -w -D INPUT -p tcp -m tcp --dport 5353 -j ACCEPT
         iptables -w -D INPUT -p udp -m udp --dport 5353 -j ACCEPT
         iptables -w -t nat -D PREROUTING -s ${GATEWAY%.*}.0/24 -d ${GATEWAY} \
         -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 5353
         iptables -w -t nat -D PREROUTING -s ${GATEWAY%.*}.0/24 -d ${GATEWAY} \
         -p udp -m udp --dport 53 -j REDIRECT --to-ports 5353
      fi
      iptables -w -D INPUT -p udp -m udp --dport 67 -j ACCEPT
   fi

   if [[ $NO_VIRT -eq 0 ]]; then
      if [[ -n "$VWIFI_IFACE" ]]; then
         ip link set down dev ${VWIFI_IFACE}
         ip addr flush ${VWIFI_IFACE}
         networkmanager_rm_unmanaged_if_needed ${VWIFI_IFACE} ${OLD_MACADDR}
         iw dev ${VWIFI_IFACE} del
         dealloc_iface $VWIFI_IFACE
      fi
   else
      ip link set down dev ${WIFI_IFACE}
      ip addr flush ${WIFI_IFACE}
      if [[ -n "$NEW_MACADDR" ]]; then
         ip link set dev ${WIFI_IFACE} address ${OLD_MACADDR}
      fi
      networkmanager_rm_unmanaged_if_needed ${WIFI_IFACE} ${OLD_MACADDR}
   fi

   mutex_unlock
   cleanup_lock
}

cleanup() {
   echo
   echo -n "Doing cleanup.. "
   _cleanup > /dev/null 2>&1
   echo "done"
}

die() {
   [[ -n "$1" ]] && echo -e "\nERROR: $1\n" >&2
   # send die signal to the main process
   [[ $BASHPID -ne $$ ]] && kill -USR2 $$
   # we don't need to call cleanup because it's traped on EXIT
   exit 1
}

clean_exit() {
   echo " "
   echo "Running Custom Clean-up";
   _clean_custom_iptables
   echo " "
   # send clean_exit signal to the main process
   [[ $BASHPID -ne $$ ]] && kill -USR1 $$
   # we don't need to call cleanup because it's traped on EXIT
   exit 0
}
