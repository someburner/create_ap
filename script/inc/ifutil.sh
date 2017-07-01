#!/bin/bash

is_interface() {
   [[ -z "$1" ]] && return 1
   [[ -d "/sys/class/net/${1}" ]]
}

is_wifi_interface() {
   which iw > /dev/null 2>&1 && iw dev $1 info > /dev/null 2>&1 && return 0
   if which iwconfig > /dev/null 2>&1 && iwconfig $1 > /dev/null 2>&1; then
      USE_IWCONFIG=1
      return 0
   fi
   return 1
}

is_bridge_interface() {
   [[ -z "$1" ]] && return 1
   [[ -d "/sys/class/net/${1}/bridge" ]]
}

get_phy_device() {
   local x
   for x in /sys/class/ieee80211/*; do
      [[ ! -e "$x" ]] && continue
      if [[ "${x##*/}" = "$1" ]]; then
         echo $1
         return 0
      elif [[ -e "$x/device/net/$1" ]]; then
         echo ${x##*/}
         return 0
      elif [[ -e "$x/device/net:$1" ]]; then
         echo ${x##*/}
         return 0
      fi
   done
   echo "Failed to get phy interface" >&2
   return 1
}

get_adapter_info() {
   local PHY
   PHY=$(get_phy_device "$1")
   [[ $? -ne 0 ]] && return 1
   iw phy $PHY info
}

get_adapter_kernel_module() {
   local MODULE
   MODULE=$(readlink -f "/sys/class/net/$1/device/driver/module")
   echo ${MODULE##*/}
}

can_be_sta_and_ap() {
   # iwconfig does not provide this information, assume false
   [[ $USE_IWCONFIG -eq 1 ]] && return 1
   if [[ "$(get_adapter_kernel_module "$1")" == "brcmfmac" ]]; then
      echo "WARN: brmfmac driver doesn't work properly with virtual interfaces and" >&2
      echo "      it can cause kernel panic. For this reason we disallow virtual" >&2
      echo "      interfaces for your adapter." >&2
      echo "      For more info: https://github.com/oblique/create_ap/issues/203" >&2
      return 1
   fi
   get_adapter_info "$1" | grep -E '{.* managed.* AP.*}' > /dev/null 2>&1 && return 0
   get_adapter_info "$1" | grep -E '{.* AP.* managed.*}' > /dev/null 2>&1 && return 0
   return 1
}

can_be_ap() {
   # iwconfig does not provide this information, assume true
   [[ $USE_IWCONFIG -eq 1 ]] && return 0
   get_adapter_info "$1" | grep -E '\* AP$' > /dev/null 2>&1 && return 0
   return 1
}

can_transmit_to_channel() {
   local IFACE CHANNEL_NUM CHANNEL_INFO
   IFACE=$1
   CHANNEL_NUM=$2

   if [[ $USE_IWCONFIG -eq 0 ]]; then
      if [[ $FREQ_BAND == 2.4 ]]; then
         CHANNEL_INFO=$(get_adapter_info ${IFACE} | grep " 24[0-9][0-9] MHz \[${CHANNEL_NUM}\]")
      else
         CHANNEL_INFO=$(get_adapter_info ${IFACE} | grep " \(49[0-9][0-9]\|5[0-9]\{3\}\) MHz \[${CHANNEL_NUM}\]")
      fi
      [[ -z "${CHANNEL_INFO}" ]] && return 1
      [[ "${CHANNEL_INFO}" == *no\ IR* ]] && return 1
      [[ "${CHANNEL_INFO}" == *disabled* ]] && return 1
      return 0
   else
      CHANNEL_NUM=$(printf '%02d' ${CHANNEL_NUM})
      CHANNEL_INFO=$(iwlist ${IFACE} channel | grep -E "Channel[[:blank:]]${CHANNEL_NUM}[[:blank:]]?:")
      [[ -z "${CHANNEL_INFO}" ]] && return 1
      return 0
   fi
}

# taken from iw/util.c
ieee80211_frequency_to_channel() {
   local FREQ=$1
   if [[ $FREQ -eq 2484 ]]; then
      echo 14
   elif [[ $FREQ -lt 2484 ]]; then
      echo $(( ($FREQ - 2407) / 5 ))
   elif [[ $FREQ -ge 4910 && $FREQ -le 4980 ]]; then
      echo $(( ($FREQ - 4000) / 5 ))
   elif [[ $FREQ -le 45000 ]]; then
      echo $(( ($FREQ - 5000) / 5 ))
   elif [[ $FREQ -ge 58320 && $FREQ -le 64800 ]]; then
      echo $(( ($FREQ - 56160) / 2160 ))
   else
      echo 0
   fi
}

is_5ghz_frequency() {
   [[ $1 =~ ^(49[0-9]{2})|(5[0-9]{3})$ ]]
}

is_wifi_connected() {
   if [[ $USE_IWCONFIG -eq 0 ]]; then
      iw dev "$1" link 2>&1 | grep -E '^Connected to' > /dev/null 2>&1 && return 0
   else
      iwconfig "$1" 2>&1 | grep -E 'Access Point: [0-9a-fA-F]{2}:' > /dev/null 2>&1 && return 0
   fi
   return 1
}

is_macaddr() {
   echo "$1" | grep -E "^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$" > /dev/null 2>&1
}

is_unicast_macaddr() {
   local x
   is_macaddr "$1" || return 1
   x=$(echo "$1" | cut -d: -f1)
   x=$(printf '%d' "0x${x}")
   [[ $(expr $x % 2) -eq 0 ]]
}

get_macaddr() {
   is_interface "$1" || return
   cat "/sys/class/net/${1}/address"
}

get_mtu() {
   is_interface "$1" || return
   cat "/sys/class/net/${1}/mtu"
}

alloc_new_iface() {
   local prefix=$1
   local i=0

   mutex_lock
   while :; do
      if ! is_interface $prefix$i && [[ ! -f $COMMON_CONFDIR/ifaces/$prefix$i ]]; then
         mkdir -p $COMMON_CONFDIR/ifaces
         touch $COMMON_CONFDIR/ifaces/$prefix$i
         echo $prefix$i
         mutex_unlock
         return
      fi
      i=$((i + 1))
   done
   mutex_unlock
}

dealloc_iface() {
   rm -f $COMMON_CONFDIR/ifaces/$1
}

get_all_macaddrs() {
   cat /sys/class/net/*/address
}

get_new_macaddr() {
   local OLDMAC NEWMAC LAST_BYTE i
   OLDMAC=$(get_macaddr "$1")
   LAST_BYTE=$(printf %d 0x${OLDMAC##*:})
   mutex_lock
   for i in {1..255}; do
      NEWMAC="${OLDMAC%:*}:$(printf %02x $(( ($LAST_BYTE + $i) % 256 )))"
      (get_all_macaddrs | grep "$NEWMAC" > /dev/null 2>&1) || break
   done
   mutex_unlock
   echo $NEWMAC
}

# start haveged when needed
haveged_watchdog() {
   local show_warn=1
   while :; do
      mutex_lock
      if [[ $(cat /proc/sys/kernel/random/entropy_avail) -lt 1000 ]]; then
         if ! which haveged > /dev/null 2>&1; then
            if [[ $show_warn -eq 1 ]]; then
               echo "WARN: Low entropy detected. We recommend you to install \`haveged'"
               show_warn=0
            fi
         elif ! pidof haveged > /dev/null 2>&1; then
            echo "Low entropy detected, starting haveged"
            # boost low-entropy
            haveged -w 1024 -p $COMMON_CONFDIR/haveged.pid
         fi
      fi
      mutex_unlock
      sleep 2
   done
}
