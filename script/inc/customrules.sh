#!/bin/bash

######  iptable Option Flags  #######
DASH_APPEND="-A"
DASH_DELETE="-D"
DASH_INSERT="-I"

ADDARG="add"
DELARG="del"
#####################################

DELAY_RULE_COUNT=0

# $1 = WIFI_IFACE; $2 drop (-D)/add (-I)
format_drop_iptable_rule () {
   local cmd="";
   local outputtmp="";
   local IFACE=$1;
   local PARAM=$2;
   cmd=(iptables -w "$PARAM" FORWARD -i ${IFACE} -d $DROP_DEST_IPMASK -p tcp --dport $DROP_DEST_PORT -m statistic --mode random --probability $DROP_OUTBOUND_PCT -j DROP);
   outputtmp="${cmd[@]}";
   echo $outputtmp
}
# ADD_DROP_OUTBOUND_CMD=$(format_drop_iptable_rule "$WIFI_IFACE" "$DASH_INSERT")  # Insert
# RM_DROP_OUTBOUND_CMD=$(format_drop_iptable_rule "$WIFI_IFACE" "$DASH_DELETE")   # Delete
#####################################

#########   Delay filter   #########
SIMPLE_DELAY=1
NORMAL_DIST_DELAY=2
DELAY_LOSS=3

DELAY_ANY=0
DELAY_OUTGOING=1
DELAY_INCOMING=2

# Set traffic control for a network / port
# tcset --device eth0 --delay 100 --network 192.168.0.0/24 --port 80
#
# Set traffic control both incoming and outgoing network
# tcset --device eth0 --direction outgoing --rate 200K --network 192.168.0.0/24
#
# Set 100ms +- 20ms network latency with normal distribution
# tcset --device eth0 --delay 100 --delay-distro 20
PREV_DELAY_CMD='';

set_delay_rule() {
   local IFACE=$1;
   local DIRECTION=$2
   local IPMASK=$3
   local PORT=$4

   local TYPE=$5;
   local DELAY=$6;

   local PARAM_DBG="Delay Type: $TYPE";
   PARAM_DBG+="\nBase delay: $DELAY (ms) ";
   PARAM_DBG+="\nNeeds Add: ";

   local NEEDS_ADD='';
   if [[ $DELAY_RULE_COUNT > 0 ]]; then
      NEEDS_ADD="--add"; PARAM_DBG+="true";
   else
      PARAM_DBG+="false";
   fi

   ## --direction ##
   local DIRECTION_ARG='';
   PARAM_DBG+="\nDirection: ";
   case "$DIRECTION" in
      "$DELAY_ANY") PARAM_DBG+="in+out"; >&2; DIRECTION_ARG="";
      ;;
      "$DELAY_OUTGOING") PARAM_DBG+="outgoing"; >&2; DIRECTION_ARG="--direction outgoing";
      ;;
      "$DELAY_INCOMING") PARAM_DBG+="incoming"; >&2; DIRECTION_ARG="--direction incoming";
      ;;
      *) echo "Invalid? DIRECTION=$DIRECTION" >&2;
         return;
      ;;
   esac
   ## ------------------------------- ##
   PARAM_DBG+="\ndevice: $IFACE";
   PARAM_DBG+="\nIP/Mask: $IPMASK :$PORT";
   local COMMON_PARAMS=(tcset --device $IFACE $DIRECTION_ARG --network $IPMASK --port $PORT)

   local ADD_DELAY_CMD='';
   PARAM_DBG+="\nName: ";
   case "$TYPE" in
      "$SIMPLE_DELAY") PARAM_DBG+="basic delay";
         ADD_DELAY_CMD=(${COMMON_PARAMS[@]} --delay $DELAY $NEEDS_ADD)
      ;;
      "$NORMAL_DIST_DELAY")
         local DELAY_DIST=$7;
         PARAM_DBG+="Delay dist=$DELAY_DIST";
         ADD_DELAY_CMD=(${COMMON_PARAMS[@]} --delay $DELAY --delay-distro $DELAY_DIST $NEEDS_ADD)
      ;;
      "$DELAY_LOSS")
         local LOSS_PCT=$7;
         PARAM_DBG+="loss pct=$LOSS_PCT %";
         ADD_DELAY_CMD=(${COMMON_PARAMS[@]} --loss $LOSS_PCT $NEEDS_ADD)
      ;;
      *) echo "Invalid or wrong arg!">&2;
         return;
      ;;
   esac

   PREV_DELAY_CMD=( "${ADD_DELAY_CMD[@]}" );
   DELAY_RULE_COUNT=$(($DELAY_RULE_COUNT+1));
   ${ADD_DELAY_CMD[@]};

   printf "\nDELAY:\n$PARAM_DBG\n";
   printf 'Full Command:\n  > '
   echo "${PREV_DELAY_CMD[@]}";
   printf "\n";
}

clear_delay_rules() {
   local IFACE=$1;
   echo 'clear_delay_rules...';
   DEL_DELAY_CMD=(tcdel --device $IFACE)
   printf "\n${DEL_DELAY_CMD[@]}\n" >&2;
   ${DEL_DELAY_CMD[@]};
   DELAY_RULE_COUNT=0;
}

# clear_delay_rules "$WIFI_IFACE" "$DELAY_TYPE";
# add_delay_rule "$WIFI_IFACE" "$DELAY_TYPE"
#
# tc qdisc add dev ap0 root netem delay 100ms          ## simple   (1)   100ms delay
# tc qdisc change dev eth0 root netem delay 100ms 10ms 25% ## moderate (2) 100 ± 10ms
# tc qdisc change dev eth0 root netem delay 100ms 20ms distribution normal ## (3) advanced
# tc -p qdisc ls dev ap0   # list rules
# tc qdisc del dev ap0 root # delete rule
#####################################
