#!/bin/bash
ARGS=( "$@" )

# Preprocessing for --config before option-parsing starts
for ((i=0; i<$#; i++)); do
   if [[ "${ARGS[i]}" = "--config" ]]; then
      if [[ -f "${ARGS[i+1]}" ]]; then
         LOAD_CONFIG="${ARGS[i+1]}"
         read_config
      else
         echo "ERROR: No config file found at given location" >&2
         exit 1
      fi
      break
   fi
done

GETOPT_ARGS=$(getopt -o hc:w:g:de:nm: -l "help","hidden","hostapd-debug:","redirect-to-localhost","mac-filter","mac-filter-accept:","isolate-clients","ieee80211n","ieee80211ac","ht_capab:","vht_capab:","driver:","no-virt","fix-unmanaged","country:","freq-band:","mac:","dhcp-dns:","daemon","stop:","list","list-running","list-clients:","version","psk","no-haveged","no-dns","no-dnsmasq","mkconfig:","config:" -n "$PROGNAME" -- "$@")
[[ $? -ne 0 ]] && exit 1
eval set -- "$GETOPT_ARGS"

while :; do
   case "$1" in
      -h|--help)
         usage
         exit 0
         ;;
      --version)
         echo $VERSION
         exit 0
         ;;
      --hidden)
         shift
         HIDDEN=1
         ;;
      --mac-filter)
         shift
         MAC_FILTER=1
         ;;
      --mac-filter-accept)
         shift
         MAC_FILTER_ACCEPT="$1"
         shift
         ;;
      --isolate-clients)
         shift
         ISOLATE_CLIENTS=1
         ;;
      -c)
         shift
         CHANNEL="$1"
         shift
         ;;
      -w)
         shift
         WPA_VERSION="$1"
         [[ "$WPA_VERSION" == "2+1" ]] && WPA_VERSION=1+2
         shift
         ;;
      -g)
         shift
         GATEWAY="$1"
         shift
         ;;
      -d)
         shift
         ETC_HOSTS=1
         ;;
      -e)
         shift
         ADDN_HOSTS="$1"
         shift
         ;;
      -n)
         shift
         SHARE_METHOD=none
         ;;
      -m)
         shift
         SHARE_METHOD="$1"
         shift
         ;;
      --ieee80211n)
         shift
         IEEE80211N=1
         ;;
      --ieee80211ac)
         shift
         IEEE80211AC=1
         ;;
      --ht_capab)
         shift
         HT_CAPAB="$1"
         shift
         ;;
      --vht_capab)
         shift
         VHT_CAPAB="$1"
         shift
         ;;
      --driver)
         shift
         DRIVER="$1"
         shift
         ;;
      --no-virt)
         shift
         NO_VIRT=1
         ;;
      --fix-unmanaged)
         shift
         FIX_UNMANAGED=1
         ;;
      --country)
         shift
         COUNTRY="$1"
         shift
         ;;
      --freq-band)
         shift
         FREQ_BAND="$1"
         shift
         ;;
      --mac)
         shift
         NEW_MACADDR="$1"
         shift
         ;;
      --dhcp-dns)
         shift
         DHCP_DNS="$1"
         shift
         ;;
      --daemon)
         shift
         DAEMONIZE=1
         ;;
      --stop)
         shift
         STOP_ID="$1"
         shift
         ;;
      --list)
         shift
         LIST_RUNNING=1
         echo -e "WARN: --list is deprecated, use --list-running instead.\n" >&2
         ;;
      --list-running)
         shift
         LIST_RUNNING=1
         ;;
      --list-clients)
         shift
         LIST_CLIENTS_ID="$1"
         shift
         ;;
      --no-haveged)
         shift
         NO_HAVEGED=1
         ;;
      --psk)
         shift
         USE_PSK=1
         ;;
      --no-dns)
         shift
         NO_DNS=1
         ;;
      --no-dnsmasq)
         shift
         NO_DNSMASQ=1
         ;;
      --redirect-to-localhost)
         shift
         REDIRECT_TO_LOCALHOST=1
         ;;
      --hostapd-debug)
         shift
         if [ "x$1" = "x1" ]; then
            HOSTAPD_DEBUG_ARGS="-d"
         elif [ "x$1" = "x2" ]; then
            HOSTAPD_DEBUG_ARGS="-dd"
         else
            printf "Error: argument for --hostapd-debug expected 1 or 2, got %s\n" "$1"
            exit 1
         fi
         shift
         ;;
      --mkconfig)
         shift
         STORE_CONFIG="$1"
         shift
         ;;
      --config)
         shift
         shift
         ;;
      --)
         shift
         break
         ;;
   esac
done

# Load positional args from config file, if needed
if [[ -n "$LOAD_CONFIG" && $# -eq 0 ]]; then
   i=0
   # set arguments in order
   for x in WIFI_IFACE INTERNET_IFACE SSID PASSPHRASE; do
      if eval "[[ -n \"\$${x}\" ]]"; then
         eval "set -- \"\${@:1:$i}\" \"\$${x}\""
         ((i++))
      fi
      # we unset the variable to avoid any problems later
      eval "unset $x"
   done
fi

# Check if required number of positional args are present
if [[ $# -lt 1 && $FIX_UNMANAGED -eq 0  && -z "$STOP_ID" &&
      $LIST_RUNNING -eq 0 && -z "$LIST_CLIENTS_ID" ]]; then
   usage >&2
   exit 1
fi

# Set NO_DNS, if dnsmasq is disabled
if [[ $NO_DNSMASQ -eq 1 ]]; then
   NO_DNS=1
fi
