#!/bin/bash

echo "Network Filter Utility" >&2;
CUR_DIR=$(pwd)
BACKUPS_DIR=$CUR_DIR/backup

##########     defaults     #########
DROP_INBOUND_EN=no
DROP_OUTBOUND_EN=no
DELAY_EN=no

### routes (remote)
DEPLOY_MASK="45.32.67.231/32";
STAGING_MASK="45.32.93.103/32";

### routes (local)
LOCAL_MASK="192.168.12.0/24";
OUTB_DROP_MASK="192.168.0.0/16";

### Ports
MQTT_PORT=1883

WIFI_IF=ap0
#####################################

########   filtering rules   ########
## Drop Packets
# DROP_DEST_IPMASK=$FLUMETECH_DEPLOY_MASK
DROP_OUTBOUND_PCT=0.20

#####################################

###########  delay rules  ###########
# Delay base for all types
# DELAY_TIME_MS=220
DELAY_TIME_MS=500

# Delay variance for type 2
DELAY_VAR_PCT=25

# Delay normal dist for type 3
DELAY_DISTRIBUTION=20
#####################################


###############################################
## Helper methods - Usage ex:
## file_exists "$LOCATION";
## if ! [[ $? -eq 0 ]]; then echo "DNE" >&2; exit 1; fi
###############################################
file_exists () {
if [ -f "$1" ];
   then echo "$1 found." >&2; return 0;
   else echo "$1 DNE !" >&2; return -1; fi
}

folder_exists () {
if [ -d "$1" ];
   then echo "$1 found." >&2; return 0;
   else echo "$1 DNE !" >&2; return -1; fi
}
###############################################


###############################################
###           Prompt (add/remove)           ###
###############################################
DELAY_ADD=1
FILTER_ADD=2
DELAY_RESTORE=3
FILTER_RESTORE=4

RUNSEL=0

prompt="
IF is $WIFI_IF
Options:
   1) Add delay
   2) Add drop filter
   3) Restore delay settings
   4) Restore filter setings
";

whattodo() {
    echo "$prompt" >&2;
    echo "Choose and press [enter]." >&2;
    read -r -p "${1:-[1-4] > } " response
    case "$response" in
        "$DELAY_ADD") return $DELAY_ADD;
        ;;
        "$FILTER_ADD") return $FILTER_ADD;
        ;;
        "$DELAY_RESTORE") return $DELAY_RESTORE;
        ;;
        "$FILTER_RESTORE") return $FILTER_RESTORE;
        ;;
        *) return 0;
         ;;
    esac
}

whattodo;
RUNSEL=$?
if [[ $RUNSEL -eq 0 ]]; then
   echo "Invalid #" >&2; exit 1;
fi
echo "RUNSEL = $SEL ($FLAVOR_DIR)" >&2;

#################################
###           Runner          ###
#################################
echo "sourcing filters.sh..."
. "./filters.sh"

# folder_exists "$BUILD_PATH";
# if [[ $? -eq 0 ]]; then

BACKUP_RESTORE_CMD=''
case "$RUNSEL" in
   "$DELAY_ADD" ) echo "Adding delay to $WIFI_IF" >&2;
   BACKUP_RESTORE_CMD=(tcshow --device $WIFI_IF --device eth1 > $BACKUPS_DIR/tcconfig-$WIFI_IF.json);
   echo "${BACKUP_RESTORE_CMD[@]}" >&2;
   ${BACKUP_RESTORE_CMD[@]};
   DELAY_EN=yes;
   ;;
   "$FILTER_ADD" ) echo "Add filter" >&2;
   CMD=(celery -A ota_app.celery shell);
   DROP_INBOUND_EN=yes;
   DROP_OUTBOUND_EN=yes;
   ;;
   "$DELAY_RESTORE" ) echo "Restore delay settings to $WIFI_IF" >&2;
   BACKUP_RESTORE_CMD=(tcset -f $BACKUPS_DIR/tcconfig-$WIFI_IF.json);
   echo "${BACKUP_RESTORE_CMD[@]}" >&2;
   ${BACKUP_RESTORE_CMD[@]};
   exit 0;
   ;;
   "$FILTER_RESTORE" ) echo "Restore filter settings to $WIFI_IF" >&2;
   clean_custom_iptables;
   exit 0;
   ;;
   #############################################################################
   * ) echo "Invalid option: $RUNSEL" >&2;
   exit 1;
   ;;
esac

# -w = 'wait for lock' || -I = 'insert'
# iptables -w -I FORWARD -i ${WIFI_IFACE} -d ${GATEWAY%.*}.0/24 -m mac --mac-source 44:85:00:ef:ba:87 -m statistic --mode random --probability 0.25 -j DROP || die

# insert drop
if [[ "$DROP_OUTBOUND_EN" == "yes" ]]; then
   format_drop_iptable_rule "$WIFI_IFACE" "$DIR_OUTGOING" "$DASH_INSERT" "$OUTB_DROP_MASK" "$MQTT_PORT" "$DROP_OUTBOUND_PCT";
   # iptables -w -I FORWARD -i ${WIFI_IFACE} -s ${GATEWAY%.*}.0/24 -j ACCEPT || die
fi

# Set delays
if [[ "$DELAY_EN" == "yes" ]]; then
   clear_delay_rules "$WIFI_IFACE";
   set_delay_rule "$WIFI_IFACE" "$DIR_OUTGOING" "$STAGING_MASK" "$MQTT_PORT" "$SIMPLE_DELAY" "$DELAY_TIME_MS";
   set_delay_rule "$WIFI_IFACE" "$DIR_OUTGOING" "$DEPLOY_MASK" "$MQTT_PORT" "$SIMPLE_DELAY" "$DELAY_TIME_MS";
   set_delay_rule "$WIFI_IFACE" "$DIR_INCOMING" "$LOCAL_MASK" "$MQTT_PORT" "$SIMPLE_DELAY" "$DELAY_TIME_MS";
fi

#################################
###          Commands         ###
#################################
# CMD_PRINT="${CMD[@]}";
# printf "venv command:\n\n"
# printf "\n-------------------------------------------------------------------\n"
# printf "${CMD_PRINT[@]}" >&2;
# printf "\n-------------------------------------------------------------------\n"
#



echo "Clean exit!"
exit 0;

#################################




### EOF
