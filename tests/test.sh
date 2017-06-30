#!/bin/bash

#########   Flags/Options   #########

DASH_APPEND="-A"
DASH_DELETE="-D"
DASH_INSERT="-I"

#####################################

#########   % DROP filter   #########
DROP_OUTBOUND_EN=yes
# DROP_OUTBOUND_EN=no
DROP_OUTBOUND_PCT=0.25
DROP_DEST_IPMASK="45.32.67.0/24"
DROP_DEST_PORT=1883

die () {
   echo 'die';
}

######  iptable Option Flags  #######
DASH_APPEND="-A"
DASH_DELETE="-D"
DASH_INSERT="-I"

ADDARG="add"
DELARG="del"
#####################################

#########  iptable routing  #########
DROP_DEST_IPMASK="45.32.67.0/24"
DROP_DEST_PORT=1883
DELAY_DEST_IPMASK="45.32.67.0/24"
DELAY_DEST_PORT=1883
#####################################

######  iptable filter en/dis  ######
# DROP_OUTBOUND_EN=yes
DROP_OUTBOUND_EN=no

DELAY_EN=yes
# DELAY_EN=no
#####################################


#######   Pct. DROP filter   ########
DROP_OUTBOUND_PCT=0.25

# $1 = WIFI_IFACE; $2 drop (-D)/add (-I)
format_drop_iptable_rule () {
   local cmd="";
   local outputtmp="";
   if [[ "$DROP_OUTBOUND_EN" == "yes" ]]; then
      local IFACE=$1;
      local PARAM=$2;
      cmd=(iptables -w "$PARAM" FORWARD -i ${IFACE} -d $DROP_DEST_IPMASK -p tcp --dport $DROP_DEST_PORT -m statistic --mode random --probability $DROP_OUTBOUND_PCT -j DROP);
   fi
   outputtmp="${cmd[@]}";
   echo $outputtmp
}
# ADD_DROP_OUTBOUND_CMD=$(format_drop_iptable_rule "$WIFI_IFACE" "$DASH_INSERT")  # Insert
# RM_DROP_OUTBOUND_CMD=$(format_drop_iptable_rule "$WIFI_IFACE" "$DASH_DELETE")   # Delete
#####################################


#########    Delay filter   #########
SIMPLE_DELAY=1
NORMAL_DIST_DELAY=2
VARIANCE_DELAY=3

# Delay base for all types
DELAY_TIME_MS=100
# Delay variance for type 2
DELAY_VAR_PCT=25
# Delay normal dist for type 3
DELAY_DISTRIBUTION=20

TC_USER=root

set_delay_rules() {
   local IFACE=$1;
   local TYPE=$2;
   local PARAM_DBG='';
   local ADD_DELAY_CMD='';
   case "$TYPE" in
      "1") echo "basic delay" >&2;
         local DELAY1=$3;
         PARAM_DBG+="Delay=$DELAY1";
         ADD_DELAY_CMD=(tcset --device $IFACE --delay $DELAY1)
      ;;
      "2") echo "normal dist delay" >&2;
         local DELAY1=$3;
         local DELAY_DIST=$4;
         PARAM_DBG+="Delay=$DELAY1";
         PARAM_DBG+="Delay dist=$DELAY_DIST";
         ADD_DELAY_CMD=(tcset --device $IFACE --delay $DELAY1 $DELAY_DIST)
      ;;
      "3") echo "variance delay" >&2;
         local DELAY1=$3;
         local DELAY_DIST=$4;
         local DELAY_PCT=$5;
         PARAM_DBG+="Delay=$DELAY1";
         PARAM_DBG+="Delay dist=$DELAY_DIST";
         PARAM_DBG+="Delay pct=$DELAY_PCT %";
         ADD_DELAY_CMD=(tcset --device $IFACE --delay $DELAY1 $DELAY_DIST $DELAY_PCT)
      ;;
      *) echo "Invalid or wrong arg!">&2;
         return;
      ;;
   esac
   printf "Adding rule: $TYPE to if $IFACE and params:\n$PARAM_DBG";
   printf "\n${ADD_DELAY_CMD[@]}\n" >&2;
   ${ADD_DELAY_CMD[@]};
}

clear_delay_rules() {
   local IFACE=$1;
   echo 'clear_delay_rules...';
   DEL_DELAY_CMD=(tcdel --device $IFACE)
   printf "\n${DEL_DELAY_CMD[@]}\n" >&2;
   ${DEL_DELAY_CMD[@]};
}

WIFI_IFACE=ap0

clear_delay_rules "$WIFI_IFACE"
res=$?
printf "\n--------clear_delay_rules--------\n";
echo "result = $res";
printf "\n---------------------------------\n";


set_delay_rules "$WIFI_IFACE" "$SIMPLE_DELAY" "100"


res=$?
printf "\n---------set_delay_rules---------\n";
echo "result = $res";
printf "\n---------------------------------\n";

exit 0;


# tc qdisc add dev ap0 root netem delay 100ms              ## simple   (1)   100ms delay
# tc qdisc change dev eth0 root netem delay 100ms 10ms 25% ## moderate (2) 100 ± 10ms
# tc qdisc change dev eth0 root netem delay 100ms 20ms distribution normal ## (3) advanced
# tc -p qdisc ls dev ap0    # list rules
# tc qdisc del dev ap0 root # delete rule

##########################################################################


# Insert
ADD_DROP_OUTBOUND_CMD=$(format_drop_iptable_rule "$WIFI_IFACE" "$DASH_INSERT")
# Delete
RM_DROP_OUTBOUND_CMD=$(format_drop_iptable_rule "$WIFI_IFACE" "$DASH_DELETE")

echo "-------------------------------------------------------------------"
printf "${RM_DROP_OUTBOUND_CMD[@]}" >&2;
printf "${ADD_DROP_OUTBOUND_CMD[@]}" >&2;
echo "-------------------------------------------------------------------"
printf "\n\n"

# ${RM_DROP_OUTBOUND_CMD[@]};
${ADD_DROP_OUTBOUND_CMD[@]} || die;

#####################################


# if [[ "$DROP_OUTBOUND_EN" == "yes" ]]; then
#    echo "Removing DROP_OUTBOUND_EN";
#    DROP_OUTBOUND_CMD=( iptables -w -D FORWARD -i ${WIFI_IFACE} -d $DROP_DEST_IPMASK -p tcp --dport $DROP_DEST_PORT -m statistic --mode random --probability $DROP_OUTBOUND_PCT -j DROP )
#    echo "-------------------------------------------------------------------"
#    echo "-------------------------------------------------------------------"
#    printf "\n\n"
#    ${DROP_OUTBOUND_CMD[@]};
# fi
##########################################################################





#### EOF
