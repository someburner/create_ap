#!/bin/bash

list_running_conf() {
   local x
   mutex_lock
   for x in /tmp/create_ap.*; do
      if [[ -f $x/pid && -f $x/wifi_iface && -d /proc/$(cat $x/pid) ]]; then
         echo $x
      fi
   done
   mutex_unlock
}

list_running() {
   local IFACE wifi_iface x
   mutex_lock
   for x in $(list_running_conf); do
      IFACE=${x#*.}
      IFACE=${IFACE%%.*}
      wifi_iface=$(cat $x/wifi_iface)

      if [[ $IFACE == $wifi_iface ]]; then
         echo $(cat $x/pid) $IFACE
      else
         echo $(cat $x/pid) $IFACE '('$(cat $x/wifi_iface)')'
      fi
   done
   mutex_unlock
}

get_wifi_iface_from_pid() {
   list_running | awk '{print $1 " " $NF}' | tr -d '\(\)' | grep -E "^${1} " | cut -d' ' -f2
}

get_pid_from_wifi_iface() {
   list_running | awk '{print $1 " " $NF}' | tr -d '\(\)' | grep -E " ${1}$" | cut -d' ' -f1
}

get_confdir_from_pid() {
   local IFACE x
   mutex_lock
   for x in $(list_running_conf); do
      if [[ $(cat $x/pid) == "$1" ]]; then
         echo $x
         break
      fi
   done
   mutex_unlock
}

print_client() {
   local line ipaddr hostname
   local mac="$1"

   if [[ -f $CONFDIR/dnsmasq.leases ]]; then
      line=$(grep " $mac " $CONFDIR/dnsmasq.leases | tail -n 1)
      ipaddr=$(echo $line | cut -d' ' -f3)
      hostname=$(echo $line | cut -d' ' -f4)
   fi

   [[ -z "$ipaddr" ]] && ipaddr="*"
   [[ -z "$hostname" ]] && hostname="*"

   printf "%-20s %-18s %s\n" "$mac" "$ipaddr" "$hostname"
}

list_clients() {
   local wifi_iface pid

   # If PID is given, get the associated wifi iface
   if [[ "$1" =~ ^[1-9][0-9]*$ ]]; then
      pid="$1"
      wifi_iface=$(get_wifi_iface_from_pid "$pid")
      [[ -z "$wifi_iface" ]] && die "'$pid' is not the pid of a running $PROGNAME instance."
   fi

   [[ -z "$wifi_iface" ]] && wifi_iface="$1"
   is_wifi_interface "$wifi_iface" || die "'$wifi_iface' is not a WiFi interface."

   [[ -z "$pid" ]] && pid=$(get_pid_from_wifi_iface "$wifi_iface")
   [[ -z "$pid" ]] && die "'$wifi_iface' is not used from $PROGNAME instance.\n\
      Maybe you need to pass the virtual interface instead.\n\
      Use --list-running to find it out."
   [[ -z "$CONFDIR" ]] && CONFDIR=$(get_confdir_from_pid "$pid")

   if [[ $USE_IWCONFIG -eq 0 ]]; then
      local awk_cmd='($1 ~ /Station$/) {print $2}'
      local client_list=$(iw dev "$wifi_iface" station dump | awk "$awk_cmd")

      if [[ -z "$client_list" ]]; then
         echo "No clients connected"
         return
      fi

      printf "%-20s %-18s %s\n" "MAC" "IP" "Hostname"

      local mac
      for mac in $client_list; do
         print_client $mac
      done
   else
      die "This option is not supported for the current driver."
   fi
}

has_running_instance() {
   local PID x

   mutex_lock
   for x in /tmp/create_ap.*; do
      if [[ -f $x/pid ]]; then
         PID=$(cat $x/pid)
         if [[ -d /proc/$PID ]]; then
            mutex_unlock
            return 0
         fi
      fi
   done
   mutex_lock

   return 1
}

is_running_pid() {
   list_running | grep -E "^${1} " > /dev/null 2>&1
}

send_stop() {
   local x

   mutex_lock
   # send stop signal to specific pid
   if is_running_pid $1; then
      kill -USR1 $1
      mutex_unlock
      return
   fi

   # send stop signal to specific interface
   for x in $(list_running | grep -E " \(?${1}( |\)?\$)" | cut -f1 -d' '); do
      kill -USR1 $x
   done
   mutex_unlock
}

# Storing configs
write_config() {
   local i=1

   if ! eval 'echo -n > "$STORE_CONFIG"' > /dev/null 2>&1; then
      echo "ERROR: Unable to create config file $STORE_CONFIG" >&2
      exit 1
   fi

   WIFI_IFACE=$1
   if [[ "$SHARE_METHOD" == "none" ]]; then
      SSID="$2"
      PASSPHRASE="$3"
   else
      INTERNET_IFACE="$2"
      SSID="$3"
      PASSPHRASE="$4"
   fi

   for config_opt in "${CONFIG_OPTS[@]}"; do
      eval echo $config_opt=\$$config_opt
   done >> "$STORE_CONFIG"

   echo -e "Config options written to '$STORE_CONFIG'"
   exit 0
}

is_config_opt() {
   local elem opt="$1"

   for elem in "${CONFIG_OPTS[@]}"; do
      if [[ "$elem" == "$opt" ]]; then
         return 0
      fi
   done
   return 1
}

# Load options from config file
read_config() {
   local opt_name opt_val line

   while read line; do
      # Read switches and their values
      opt_name="${line%%=*}"
      opt_val="${line#*=}"
      if is_config_opt "$opt_name" ; then
         eval $opt_name="\$opt_val"
      else
         echo "WARN: Unrecognized configuration entry $opt_name" >&2
      fi
   done < "$LOAD_CONFIG"
}
