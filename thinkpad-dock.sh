#!/bin/sh -e

# Save this file as /usr/local/sbin/thinkpad-dock.sh

# NB: you will need to create the xrandr_<hostname>_(sh)docked.sh scripts
# comprising xrandr commands to suit your setup in your ~/bin/.

switch_to_undocked () {
  logger -t DOCKING "Switching displays to undocked mode"
  su $username -c "/home/$username/bin/xrandr_$(hostname)_undocked.sh"
}

switch_to_docked () {
  logger -t DOCKING "Switching displays to docked mode"
  su $username -c "/home/$username/bin/xrandr_$(hostname)_docked.sh"
}

thinkpad_dock_main () {
  # Get name of user logged into X (attached to tty7)
  username=$(w -hs | grep tty7 | cut -f1 -d ' ')
  if [ -z ${username} ]; then
    logger -t DOCKING "Nobody seems to be logged in - aborting"
    return 1
  fi

  if [ "$ACTION" = "add" ]; then
    DOCKED=1
    logger -t DOCKING "Detected condition: docked"
  elif [ "$ACTION" = "remove" ]; then
    DOCKED=0
    logger -t DOCKING "Detected condition: un-docked"
  else
    logger -t DOCKING "Detected condition: unknown"
    echo Please set env var \$ACTION to 'add' or 'remove'
    return 1
  fi

  # invoke from XSetup with NO_KDM_REBOOT otherwise you'll end up in a KDM reboot loop
  NO_KDM_REBOOT=0
  for p in $*; do
    case "$p" in
    "NO_KDM_REBOOT") NO_KDM_REBOOT=1 ;;
    "SWITCH_TO_LOCAL") DOCKED=0 ;;
    esac
  done

  export DISPLAY=:0
  #export XAUTHORITY=$(find /var/run/kdm -name "A${DISPLAY}-*")
  #export XAUTHORITY=/var/run/lightdm/${username}/xauthority

  case "$DOCKED" in
    "0")
      switch_to_undocked ;;
    "1")
      switch_to_docked ;;
  esac
}

# Stolen from https://stackoverflow.com/a/28776166/1905491
detect_sourced () {
  notsourced=1
  if [ -n "$ZSH_EVAL_CONTEXT" ]; then 
    case $ZSH_EVAL_CONTEXT in *:file) notsourced=0;; esac
  elif [ -n "$KSH_VERSION" ]; then
    [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && notsourced=1
  elif [ -n "$BASH_VERSION" ]; then
    (return 2>/dev/null) && notsourced=0
  else # All other shells: examine $0 for known shell binary filenames
    # Detects `sh` and `dash`; add additional shell filenames as needed.
    case ${0##*/} in sh|dash) notsourced=0;; esac
  fi
  echo notsourced=$notsourced
  return $notsourced
}

if ! detect_sourced ; then
  thinkpad_dock_main $@
fi
