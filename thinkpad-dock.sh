#!/bin/sh -e

# Save this file as /usr/local/sbin/thinkpad-dock.sh

# NB: you will need to modify the username and tweak the xrandr
# commands to suit your setup.

# Get name of user logged into X (attached to tty7)
username=$(w -hs | grep tty7 | cut -f1 -d ' ')
if [ -z ${username} ]; then
  logger -t DOCKING "Nobody seems to be logged in - aborting"
  exit 0
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
  exit 1
fi

# invoke from XSetup with NO_KDM_REBOOT otherwise you'll end up in a KDM reboot loop
NO_KDM_REBOOT=0
for p in $*; do
  case "$p" in
  "NO_KDM_REBOOT") NO_KDM_REBOOT=1 ;;
  "SWITCH_TO_LOCAL") DOCKED=0 ;;
  esac
done

switch_to_undocked () {
  logger -t DOCKING "Switching off HDMI2/3 and switching on LVDS1"
  su $username -c '
    /usr/bin/xrandr \
      --output HDMI1 --off \
      --output HDMI2 --off \
      --output HDMI3 --off \
      --output VGA1  --off \
      --output eDP1  --auto \
      --output LVDS1 --auto \
    '
}

switch_to_docked () {

  # The Display port on the docking station is on HDMI2 - let's use it and turn off local display
  logger -t DOCKING "Switching off LVDS1 and switching on HDMI2/3"

  su $username -c '
    /usr/bin/xrandr \
      --output eDP1  --off \
      --output LVDS1 --off \
      --output HDMI1 --auto \
      --output HDMI2 --auto --pos 1680x0 --rotate left \
      --output HDMI3 --auto --pos 0x600 --primary \
      --output VGA1  --auto \
    '
  # alternative:
  # xrandr --output LVDS1 --off --output HDMI3 --primary --auto --pos 0x0
  # --output HDMI2 --auto --rotate left --pos 1680x-600

  # this will probably fail ("Configure crtc 2 failed"):
  #/usr/bin/xrandr --output LVDS1 --auto
}

export DISPLAY=:0
#export XAUTHORITY=$(find /var/run/kdm -name "A${DISPLAY}-*")
#export XAUTHORITY=/var/run/lightdm/${username}/xauthority

case "$DOCKED" in
  "0")
    switch_to_undocked ;;
  "1")
    switch_to_docked ;;
esac
