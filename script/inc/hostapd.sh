#!/bin/bash

HOSTAPD=$(which hostapd)

if [[ ! -x "$HOSTAPD" ]]; then
   echo "ERROR: hostapd not found." >&2
   exit 1
fi

if_setup_checks() {
if [[ $(get_adapter_kernel_module ${WIFI_IFACE}) =~ ^(8192[cd][ue]|8723a[sue])$ ]]; then
   if ! strings "$HOSTAPD" | grep -m1 rtl871xdrv > /dev/null 2>&1; then
      echo "ERROR: You need to patch your hostapd with rtl871xdrv patches." >&2
      exit 1
   fi

   if [[ $DRIVER != "rtl871xdrv" ]]; then
      echo "WARN: Your adapter needs rtl871xdrv, enabling --driver=rtl871xdrv" >&2
      DRIVER=rtl871xdrv
   fi
fi

if [[ "$SHARE_METHOD" != "nat" && "$SHARE_METHOD" != "bridge" && "$SHARE_METHOD" != "none" ]]; then
   echo "ERROR: Wrong Internet sharing method" >&2
   echo
   usage >&2
   exit 1
fi

if [[ -n "$NEW_MACADDR" ]]; then
   if ! is_macaddr "$NEW_MACADDR"; then
      echo "ERROR: '${NEW_MACADDR}' is not a valid MAC address" >&2
      exit 1
   fi

   if ! is_unicast_macaddr "$NEW_MACADDR"; then
      echo "ERROR: The first byte of MAC address (${NEW_MACADDR}) must be even" >&2
      exit 1
   fi

   if [[ $(get_all_macaddrs | grep -c ${NEW_MACADDR}) -ne 0 ]]; then
      echo "WARN: MAC address '${NEW_MACADDR}' already exists. Because of this, you may encounter some problems" >&2
   fi
fi
}
# end if_setup()


hostapd_write_config() {
echo "hostapd_write_config"
cat << EOF > $CONFDIR/hostapd.conf
beacon_int=100
ssid=${SSID}
interface=${WIFI_IFACE}
driver=${DRIVER}
channel=${CHANNEL}
ctrl_interface=$CONFDIR/hostapd_ctrl
ctrl_interface_group=0
ignore_broadcast_ssid=$HIDDEN
ap_isolate=$ISOLATE_CLIENTS
EOF

if [[ -n "$COUNTRY" ]]; then
   cat << EOF >> $CONFDIR/hostapd.conf
country_code=${COUNTRY}
ieee80211d=1
EOF
fi

if [[ $FREQ_BAND == 2.4 ]]; then
   echo "hw_mode=g" >> $CONFDIR/hostapd.conf
else
   echo "hw_mode=a" >> $CONFDIR/hostapd.conf
fi

if [[ $MAC_FILTER -eq 1 ]]; then
   cat << EOF >> $CONFDIR/hostapd.conf
macaddr_acl=${MAC_FILTER}
accept_mac_file=${MAC_FILTER_ACCEPT}
EOF
fi

if [[ $IEEE80211N -eq 1 ]]; then
   cat << EOF >> $CONFDIR/hostapd.conf
ieee80211n=1
ht_capab=${HT_CAPAB}
EOF
fi

if [[ $IEEE80211AC -eq 1 ]]; then
   echo "ieee80211ac=1" >> $CONFDIR/hostapd.conf
fi

if [[ -n "$VHT_CAPAB" ]]; then
   echo "vht_capab=${VHT_CAPAB}" >> $CONFDIR/hostapd.conf
fi

if [[ $IEEE80211N -eq 1 ]] || [[ $IEEE80211AC -eq 1 ]]; then
   echo "wmm_enabled=1" >> $CONFDIR/hostapd.conf
fi

if [[ -n "$PASSPHRASE" ]]; then
   [[ "$WPA_VERSION" == "1+2" ]] && WPA_VERSION=3
   if [[ $USE_PSK -eq 0 ]]; then
      WPA_KEY_TYPE=passphrase
   else
      WPA_KEY_TYPE=psk
   fi
   cat << EOF >> $CONFDIR/hostapd.conf
wpa=${WPA_VERSION}
wpa_${WPA_KEY_TYPE}=${PASSPHRASE}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
EOF
fi

if [[ "$SHARE_METHOD" == "bridge" ]]; then
   echo "bridge=${BRIDGE_IFACE}" >> $CONFDIR/hostapd.conf
elif [[ $NO_DNSMASQ -eq 0 ]]; then
   # dnsmasq config (dhcp + dns)
   DNSMASQ_VER=$(dnsmasq -v | grep -m1 -oE '[0-9]+(\.[0-9]+)*\.[0-9]+')
   version_cmp $DNSMASQ_VER 2.63
   if [[ $? -eq 1 ]]; then
      DNSMASQ_BIND=bind-interfaces
   else
      DNSMASQ_BIND=bind-dynamic
   fi
   if [[ "$DHCP_DNS" == "gateway" ]]; then
      DHCP_DNS="$GATEWAY"
   fi
   cat << EOF > $CONFDIR/dnsmasq.conf
listen-address=${GATEWAY}
${DNSMASQ_BIND}
dhcp-range=${GATEWAY%.*}.1,${GATEWAY%.*}.254,255.255.255.0,24h
dhcp-option-force=option:router,${GATEWAY}
dhcp-option-force=option:dns-server,${DHCP_DNS}
EOF
   MTU=$(get_mtu $INTERNET_IFACE)
   [[ -n "$MTU" ]] && echo "dhcp-option-force=option:mtu,${MTU}" >> $CONFDIR/dnsmasq.conf
   [[ $ETC_HOSTS -eq 0 ]] && echo no-hosts >> $CONFDIR/dnsmasq.conf
   [[ -n "$ADDN_HOSTS" ]] && echo "addn-hosts=${ADDN_HOSTS}" >> $CONFDIR/dnsmasq.conf
   if [[ "$SHARE_METHOD" == "none" && "$REDIRECT_TO_LOCALHOST" == "1" ]]; then
      cat << EOF >> $CONFDIR/dnsmasq.conf
address=/#/$GATEWAY
EOF
   fi
fi
}
# end hostapd_write_config()
