#!/bin/bash

get_bridge_iface() {
   if [[ "$SHARE_METHOD" == "bridge" ]]; then
      if is_bridge_interface $INTERNET_IFACE; then
         BRIDGE_IFACE=$INTERNET_IFACE
      else
         BRIDGE_IFACE=$(alloc_new_iface br)
      fi
   fi
}

init_bridge_sharing() {
   # disable iptables rules for bridged interfaces
   if [[ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]]; then
      echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables
   fi
   # to initialize the bridge interface correctly we need to do the following:
   #
   # 1) save the IPs and route table of INTERNET_IFACE
   # 2) if NetworkManager is running set INTERNET_IFACE as unmanaged
   # 3) create BRIDGE_IFACE and attach INTERNET_IFACE to it
   # 4) set the previously saved IPs and route table to BRIDGE_IFACE
   #
   # we need the above because BRIDGE_IFACE is the master interface from now on
   # and it must know where is connected, otherwise connection is lost.
   if ! is_bridge_interface $INTERNET_IFACE; then
      echo -n "Create a bridge interface... "
      OLD_IFS="$IFS"
      IFS=$'\n'

      IP_ADDRS=( $(ip addr show $INTERNET_IFACE | grep -A 1 -E 'inet[[:blank:]]' | paste - -) )
      ROUTE_ADDRS=( $(ip route show dev $INTERNET_IFACE) )

      IFS="$OLD_IFS"

      if networkmanager_is_running; then
         networkmanager_add_unmanaged $INTERNET_IFACE
         networkmanager_wait_until_unmanaged $INTERNET_IFACE
      fi

      # create bridge interface
      ip link add name $BRIDGE_IFACE type bridge || die
      ip link set dev $BRIDGE_IFACE up || die
      # set 0ms forward delay
      echo 0 > /sys/class/net/$BRIDGE_IFACE/bridge/forward_delay

      # attach internet interface to bridge interface
      ip link set dev $INTERNET_IFACE promisc on || die
      ip link set dev $INTERNET_IFACE up || die
      ip link set dev $INTERNET_IFACE master $BRIDGE_IFACE || die

      ip addr flush $INTERNET_IFACE
      for x in "${IP_ADDRS[@]}"; do
         x="${x/inet/}"
         x="${x/secondary/}"
         x="${x/dynamic/}"
         x=$(echo $x | sed 's/\([0-9]\)sec/\1/g')
         x="${x/${INTERNET_IFACE}/}"
         ip addr add $x dev $BRIDGE_IFACE || die
      done

      # remove any existing entries that were added from 'ip addr add'
      ip route flush dev $INTERNET_IFACE
      ip route flush dev $BRIDGE_IFACE

      # we must first add the entries that specify the subnets and then the
      # gateway entry, otherwise 'ip addr add' will return an error
      for x in "${ROUTE_ADDRS[@]}"; do
         [[ "$x" == default* ]] && continue
         ip route add $x dev $BRIDGE_IFACE || die
      done

      for x in "${ROUTE_ADDRS[@]}"; do
         [[ "$x" != default* ]] && continue
         ip route add $x dev $BRIDGE_IFACE || die
      done

      echo "$BRIDGE_IFACE created."
   fi
}
# init_bridge_sharing


###
