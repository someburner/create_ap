#!/bin/bash

init_vwifi() {
   if [[ $NO_VIRT -eq 0 ]]; then
      VWIFI_IFACE=$(alloc_new_iface ap)

      # in NetworkManager 0.9.9 and above we can set the interface as unmanaged without
      # the need of MAC address, so we set it before we create the virtual interface.
      if networkmanager_is_running && [[ $NM_OLDER_VERSION -eq 0 ]]; then
         echo -n "Network Manager found, set ${VWIFI_IFACE} as unmanaged device... "
         networkmanager_add_unmanaged ${VWIFI_IFACE}
         # do not call networkmanager_wait_until_unmanaged because interface does not
         # exist yet
         echo "DONE"
      fi

      if is_wifi_connected ${WIFI_IFACE}; then
         WIFI_IFACE_FREQ=$(iw dev ${WIFI_IFACE} link | grep -i freq | awk '{print $2}')
         WIFI_IFACE_CHANNEL=$(ieee80211_frequency_to_channel ${WIFI_IFACE_FREQ})
         echo -n "${WIFI_IFACE} is already associated with channel ${WIFI_IFACE_CHANNEL} (${WIFI_IFACE_FREQ} MHz)"
         if is_5ghz_frequency $WIFI_IFACE_FREQ; then
            FREQ_BAND=5
         else
            FREQ_BAND=2.4
         fi
         if [[ $WIFI_IFACE_CHANNEL -ne $CHANNEL ]]; then
            echo ", fallback to channel ${WIFI_IFACE_CHANNEL}"
            CHANNEL=$WIFI_IFACE_CHANNEL
         else
            echo
         fi
      fi

      VIRTDIEMSG="Maybe your WiFi adapter does not fully support virtual interfaces.
            Try again with --no-virt."
      echo -n "Creating a virtual WiFi interface... "

      if iw dev ${WIFI_IFACE} interface add ${VWIFI_IFACE} type __ap; then
         # now we can call networkmanager_wait_until_unmanaged
         networkmanager_is_running && [[ $NM_OLDER_VERSION -eq 0 ]] && networkmanager_wait_until_unmanaged ${VWIFI_IFACE}
         echo "${VWIFI_IFACE} created." >&2;
         RM_WIFI_IF=$VWIFI_IFACE
      else
         VWIFI_IFACE=
         die "$VIRTDIEMSG"
      fi
      OLD_MACADDR=$(get_macaddr ${VWIFI_IFACE})
      if [[ -z "$NEW_MACADDR" && $(get_all_macaddrs | grep -c ${OLD_MACADDR}) -ne 1 ]]; then
         NEW_MACADDR=$(get_new_macaddr ${VWIFI_IFACE})
      fi
      WIFI_IFACE=${VWIFI_IFACE}
   else
      OLD_MACADDR=$(get_macaddr ${WIFI_IFACE})
   fi
}
