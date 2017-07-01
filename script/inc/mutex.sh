#!/bin/bash

cleanup_lock() {
   rm -f $COUNTER_LOCK_FILE
}

init_lock() {
   local LOCK_FILE=/tmp/create_ap.all.lock

   # we initialize only once
   [[ $LOCK_FD -ne 0 ]] && return 0

   LOCK_FD=$(get_avail_fd)
   [[ $LOCK_FD -eq 0 ]] && return 1

   # open/create lock file with write access for all users
   # otherwise normal users will not be able to use it.
   # to avoid race conditions on creation, we need to
   # use umask to set the permissions.
   umask 0555
   eval "exec $LOCK_FD>$LOCK_FILE" > /dev/null 2>&1 || return 1
   umask $SCRIPT_UMASK

   # there is a case where lock file was created from a normal
   # user. change the owner to root as soon as we can.
   [[ $(id -u) -eq 0 ]] && chown 0:0 $LOCK_FILE

   # create mutex counter lock file
   echo 0 > $COUNTER_LOCK_FILE

   return $?
}

# recursive mutex lock for all create_ap processes
mutex_lock() {
   local counter_mutex_fd
   local counter

   # lock local mutex and read counter
   counter_mutex_fd=$(get_avail_fd)
   if [[ $counter_mutex_fd -ne 0 ]]; then
      eval "exec $counter_mutex_fd<>$COUNTER_LOCK_FILE"
      flock $counter_mutex_fd
      read -u $counter_mutex_fd counter
   else
      echo "Failed to lock mutex counter" >&2
      return 1
   fi

   # lock global mutex and increase counter
   [[ $counter -eq 0 ]] && flock $LOCK_FD
   counter=$(( $counter + 1 ))

   # write counter and unlock local mutex
   echo $counter > /proc/$BASHPID/fd/$counter_mutex_fd
   eval "exec ${counter_mutex_fd}<&-"
   return 0
}

# recursive mutex unlock for all create_ap processes
mutex_unlock() {
   local counter_mutex_fd
   local counter

   # lock local mutex and read counter
   counter_mutex_fd=$(get_avail_fd)
   if [[ $counter_mutex_fd -ne 0 ]]; then
      eval "exec $counter_mutex_fd<>$COUNTER_LOCK_FILE"
      flock $counter_mutex_fd
      read -u $counter_mutex_fd counter
   else
      echo "Failed to lock mutex counter" >&2
      return 1
   fi

   # decrease counter and unlock global mutex
   if [[ $counter -gt 0 ]]; then
      counter=$(( $counter - 1 ))
      [[ $counter -eq 0 ]] && flock -u $LOCK_FD
   fi

   # write counter and unlock local mutex
   echo $counter > /proc/$BASHPID/fd/$counter_mutex_fd
   eval "exec ${counter_mutex_fd}<&-"
   return 0
}
