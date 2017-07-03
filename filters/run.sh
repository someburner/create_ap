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

WIFI_IF="ap0"

USER=jeffrey
# TC_CFG_NAME="$WIFI_IF"
TC_CFG_NAME="tcconfig.json"
TC_CFG_PATH="$BACKUPS_DIR/$TC_CFG_NAME"
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
SHOW_DELAY=3
SHOW_TABLES=4
DELAY_RESTORE=5
FILTER_RESTORE=6

RUNSEL=0

prompt="
IF is $WIFI_IF
Options:
   1) Add delay
   2) Add drop filter
   3) Show delay settings
   4) Show filter settings (iptables)
   5) Restore delay settings
   6) Restore filter setings
";

whattodo() {
    echo "$prompt" >&2;
    echo "Choose and press [enter]." >&2;
    read -r -p "${1:-[1-4] > } " response
    case "$response" in
        "$DELAY_ADD") return $DELAY_ADD; ;;
        "$FILTER_ADD") return $FILTER_ADD; ;;
        "$SHOW_DELAY") return $SHOW_DELAY; ;;
        "$SHOW_TABLES") return $SHOW_TABLES; ;;
        "$DELAY_RESTORE") return $DELAY_RESTORE; ;;
        "$FILTER_RESTORE") return $FILTER_RESTORE; ;;
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


echo "sourcing filters.sh..."
. "./filters.sh"


#################################
###       Save/Restore        ###
#################################
save_tc() {
   local IF=$1; local LOC=$2;
   folder_exists "$BACKUPS_DIR";
   if ! [[ $? -eq 0 ]]; then echo "Backup loc DNE!"; exit 0; fi
   file_exists "$LOC";
   if [[ $? -eq 0 ]]; then echo "Backup exists"; return 0; fi
   local CMD=(tcshow --device $IF);
   ########################
OUTPUT="$( bash <<EOF
${CMD[@]};
EOF
)";
   ########################
   echo "$OUTPUT" > "$LOC";
   chmod 755 $LOC;
   chown $USER:$USER $LOC;
}
### save_tc

restore_tc() {
   local LOC=$1;
   local CMD=(tcset -f $LOC);
   ${CMD[@]};
   local res=$?;
   echo "restore result: $res ($LOC)";
   return $res;
}

delete_tc() {
   local IF=$1;
   local CMD=(tcdel --device $IF);
   ${CMD[@]};
   return $?;
}
### delete_tc
###########################################

#################################
###           Runner          ###
#################################

case "$RUNSEL" in
   "$DELAY_ADD" ) echo "Adding delay to $WIFI_IF" >&2;
   save_tc "$WIFI_IF" "$TC_CFG_PATH"
   DELAY_EN=yes;
   ;;
   "$FILTER_ADD" ) echo "Add filter" >&2;
   DROP_INBOUND_EN=yes;
   DROP_OUTBOUND_EN=yes;
   ;;
   "$SHOW_DELAY" ) echo "Show delays" >&2;
   local CMD=(tcshow --device $WIFI_IF);
   ${CMD[@]}; exit 0;
   ;;
   "$SHOW_TABLES" ) echo "Show filters" >&2;
   local CMD=(iptables -L);
   ${CMD[@]}; exit 0;
   ;;
   "$DELAY_RESTORE" ) echo "Restore delay settings to $WIFI_IF" >&2;
   # restore_tc "$TC_CFG_PATH";
   delete_tc "$WIFI_IF";
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

# Set delays
if [[ "$DELAY_EN" == "yes" ]]; then
   echo "Setting delays...";
   clear_delay_rules "$WIFI_IF";
   set_delay_rule "$WIFI_IF" "$DIR_OUTGOING" "$STAGING_MASK" "$MQTT_PORT" "$SIMPLE_DELAY" "$DELAY_TIME_MS";
   set_delay_rule "$WIFI_IF" "$DIR_OUTGOING" "$DEPLOY_MASK" "$MQTT_PORT" "$SIMPLE_DELAY" "$DELAY_TIME_MS";
   set_delay_rule "$WIFI_IF" "$DIR_INCOMING" "$LOCAL_MASK" "$MQTT_PORT" "$SIMPLE_DELAY" "$DELAY_TIME_MS";
fi

# -w = 'wait for lock' || -I = 'insert'
# iptables -w -I FORWARD -i ${WIFI_IFACE} -d ${GATEWAY%.*}.0/24 -m mac --mac-source 44:85:00:ef:ba:87 -m statistic --mode random --probability 0.25 -j DROP || die

# insert drop
if [[ "$DROP_OUTBOUND_EN" == "yes" ]]; then
   format_drop_iptable_rule "$WIFI_IF" "$DIR_OUTGOING" "$DASH_INSERT" "$OUTB_DROP_MASK" "$MQTT_PORT" "$DROP_OUTBOUND_PCT";
   # iptables -w -I FORWARD -i ${WIFI_IFACE} -s ${GATEWAY%.*}.0/24 -j ACCEPT || die
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
