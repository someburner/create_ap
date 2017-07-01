#!/bin/bash

NETWORKMANAGER_CONF=/etc/NetworkManager/NetworkManager.conf
NM_OLDER_VERSION=1

networkmanager_exists() {
   local NM_VER
   which nmcli > /dev/null 2>&1 || return 1
   NM_VER=$(nmcli -v | grep -m1 -oE '[0-9]+(\.[0-9]+)*\.[0-9]+')
   version_cmp $NM_VER 0.9.9
   if [[ $? -eq 1 ]]; then
      NM_OLDER_VERSION=1
   else
      NM_OLDER_VERSION=0
   fi
   return 0
}

networkmanager_is_running() {
   local NMCLI_OUT
   networkmanager_exists || return 1
   if [[ $NM_OLDER_VERSION -eq 1 ]]; then
      NMCLI_OUT=$(nmcli -t -f RUNNING nm 2>&1 | grep -E '^running$')
   else
      NMCLI_OUT=$(nmcli -t -f RUNNING g 2>&1 | grep -E '^running$')
   fi
   [[ -n "$NMCLI_OUT" ]]
}

networkmanager_iface_is_unmanaged() {
   is_interface "$1" || return 2
   (nmcli -t -f DEVICE,STATE d 2>&1 | grep -E "^$1:unmanaged$" > /dev/null 2>&1) || return 1
}

ADDED_UNMANAGED=

networkmanager_add_unmanaged() {
   local MAC UNMANAGED WAS_EMPTY x
   networkmanager_exists || return 1

   [[ -d ${NETWORKMANAGER_CONF%/*} ]] || mkdir -p ${NETWORKMANAGER_CONF%/*}
   [[ -f ${NETWORKMANAGER_CONF} ]] || touch ${NETWORKMANAGER_CONF}

   if [[ $NM_OLDER_VERSION -eq 1 ]]; then
      if [[ -z "$2" ]]; then
         MAC=$(get_macaddr "$1")
      else
         MAC="$2"
      fi
      [[ -z "$MAC" ]] && return 1
   fi

   mutex_lock
   UNMANAGED=$(grep -m1 -Eo '^unmanaged-devices=[[:alnum:]:;,-]*' /etc/NetworkManager/NetworkManager.conf)

   WAS_EMPTY=0
   [[ -z "$UNMANAGED" ]] && WAS_EMPTY=1
   UNMANAGED=$(echo "$UNMANAGED" | sed 's/unmanaged-devices=//' | tr ';,' ' ')

   # if it exists, do nothing
   for x in $UNMANAGED; do
      if [[ $x == "mac:${MAC}" ]] ||
            [[ $NM_OLDER_VERSION -eq 0 && $x == "interface-name:${1}" ]]; then
         mutex_unlock
         return 2
      fi
   done

   if [[ $NM_OLDER_VERSION -eq 1 ]]; then
      UNMANAGED="${UNMANAGED} mac:${MAC}"
   else
      UNMANAGED="${UNMANAGED} interface-name:${1}"
   fi

   UNMANAGED=$(echo $UNMANAGED | sed -e 's/^ //')
   UNMANAGED="${UNMANAGED// /;}"
   UNMANAGED="unmanaged-devices=${UNMANAGED}"

   if ! grep -E '^\[keyfile\]' ${NETWORKMANAGER_CONF} > /dev/null 2>&1; then
      echo -e "\n\n[keyfile]\n${UNMANAGED}" >> ${NETWORKMANAGER_CONF}
   elif [[ $WAS_EMPTY -eq 1 ]]; then
      sed -e "s/^\(\[keyfile\].*\)$/\1\n${UNMANAGED}/" -i ${NETWORKMANAGER_CONF}
   else
      sed -e "s/^unmanaged-devices=.*/${UNMANAGED}/" -i ${NETWORKMANAGER_CONF}
   fi

   ADDED_UNMANAGED="${ADDED_UNMANAGED} ${1} "
   mutex_unlock

   local nm_pid=$(pidof NetworkManager)
   [[ -n "$nm_pid" ]] && kill -HUP $nm_pid

   return 0
}

networkmanager_rm_unmanaged() {
   local MAC UNMANAGED
   networkmanager_exists || return 1
   [[ ! -f ${NETWORKMANAGER_CONF} ]] && return 1

   if [[ $NM_OLDER_VERSION -eq 1 ]]; then
      if [[ -z "$2" ]]; then
         MAC=$(get_macaddr "$1")
      else
         MAC="$2"
      fi
      [[ -z "$MAC" ]] && return 1
   fi

   mutex_lock
   UNMANAGED=$(grep -m1 -Eo '^unmanaged-devices=[[:alnum:]:;,-]*' /etc/NetworkManager/NetworkManager.conf | sed 's/unmanaged-devices=//' | tr ';,' ' ')

   if [[ -z "$UNMANAGED" ]]; then
      mutex_unlock
      return 1
   fi

   [[ -n "$MAC" ]] && UNMANAGED=$(echo $UNMANAGED | sed -e "s/mac:${MAC}\( \|$\)//g")
   UNMANAGED=$(echo $UNMANAGED | sed -e "s/interface-name:${1}\( \|$\)//g")
   UNMANAGED=$(echo $UNMANAGED | sed -e 's/ $//')

   if [[ -z "$UNMANAGED" ]]; then
      sed -e "/^unmanaged-devices=.*/d" -i ${NETWORKMANAGER_CONF}
   else
      UNMANAGED="${UNMANAGED// /;}"
      UNMANAGED="unmanaged-devices=${UNMANAGED}"
      sed -e "s/^unmanaged-devices=.*/${UNMANAGED}/" -i ${NETWORKMANAGER_CONF}
   fi

   ADDED_UNMANAGED="${ADDED_UNMANAGED/ ${1} /}"
   mutex_unlock

   local nm_pid=$(pidof NetworkManager)
   [[ -n "$nm_pid" ]] && kill -HUP $nm_pid

   return 0
}

networkmanager_fix_unmanaged() {
   [[ -f ${NETWORKMANAGER_CONF} ]] || return

   mutex_lock
   sed -e "/^unmanaged-devices=.*/d" -i ${NETWORKMANAGER_CONF}
   mutex_unlock

   local nm_pid=$(pidof NetworkManager)
   [[ -n "$nm_pid" ]] && kill -HUP $nm_pid
}

networkmanager_rm_unmanaged_if_needed() {
   [[ $ADDED_UNMANAGED =~ .*\ ${1}\ .* ]] && networkmanager_rm_unmanaged $1 $2
}

networkmanager_wait_until_unmanaged() {
   local RES
   networkmanager_is_running || return 1
   while :; do
      networkmanager_iface_is_unmanaged "$1"
      RES=$?
      [[ $RES -eq 0 ]] && break
      [[ $RES -eq 2 ]] && die "Interface '${1}' does not exist.
      It's probably renamed by a udev rule."
      sleep 1
   done
   sleep 2
   return 0
}
