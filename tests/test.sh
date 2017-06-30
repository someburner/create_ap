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
DELAY_TYPE=1
# DELAY_TYPE=2
# DELAY_TYPE=3

# Delay base for all types
DELAY_TIME_MS=100
# Delay variance for type 2
DELAY_VAR_PCT=25
# Delay normal dist for type 3
DELAY_DISTRIBUTION=20

TC_USER=root

format_delay_rule () {
   local cmd="";
   local outputtmp="";
   if [[ "$DELAY_EN" == "yes" ]]; then
      local IFACE=$1;
      local PARAM=$2;
      local TYPE=$3;
      local cmdswitch="";
      case $TYPE in
         "1") echo "basic delay" >&2; cmdswitch="$DELAY_TIME_MS"; cmdswitch+="ms";
         ;;
         "2") echo "variance delay" >&2; cmdswitch="$DELAY_TIME_MS"; cmdswitch+="ms";
         ;;
         "3") echo "normal dist delay" >&2; cmdswitch="$DELAY_TIME_MS"; cmdswitch+="ms";
         ;;
         *) echo "Invalid or wrong arg!">&2; echo "Call with '1' for debug or '2' for release." >&2;
         echo '';
         ;;
      esac
      cmd=(tc qdisc "$PARAM" dev "$IFACE" "$TC_USER" netem delay $cmdswitch);
   fi
   outputtmp="${cmd[@]}";
   echo $outputtmp
}

WIFI_IFACE=ap0


clear_delay_rules() {
   local IFACE=$1;
   local TYPE=$2;
   local DEL_DELAY_CMD='';
   LIST_DELAY_CMD=$(eval 'tc -p qdisc ls dev $IFACE')
   if [[ "$LIST_DELAY_CMD" != "" ]]; then
      DEL_DELAY_CMD=$(format_delay_rule "$IFACE" "$DELARG" "$TYPE")
      echo "$LIST_DELAY_CMD - exists!";
      echo 'Deleting...';
      ${DEL_DELAY_CMD[@]};
   else
      echo 'DNE';
   fi
}

# clear_delay_rules "$WIFI_IFACE" "$DELAY_TYPE";
# exit 0

add_delay_rule() {
   local IFACE=$1;
   local TYPE=$2;
   LIST_DELAY_CMD=$(eval 'tc -p qdisc ls dev $IFACE')
   if [[ "$LIST_DELAY_CMD" == "" ]]; then
      ADD_DELAY_CMD=$(format_delay_rule "$IFACE" "$ADDARG" "$TYPE")
      ${ADD_DELAY_CMD[@]};
      printf "${DEL_DELAY_CMD[@]}\n";
   else
      printf "Delay already set!\n";
   fi
}

add_delay_rule "$WIFI_IFACE" "$DELAY_TYPE"


# ADD_DELAY_CMD=$(format_delay_rule "$WIFI_IFACE" "$ADDARG")
# DEL_DELAY_CMD=$(format_delay_rule "$WIFI_IFACE" "$DELARG")

# echo "DELAY_LIST_CMD == $DELAY_LIST_CMD"
# if [[ "$LIST_DELAY_CMD" != "" ]]; then
#    echo 'exists!';
#    ${DEL_DELAY_CMD[@]};
# else
#    echo 'DNE!';
#    ${ADD_DELAY_CMD[@]};
#    printf "${DEL_DELAY_CMD[@]}\n";
# fi

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
