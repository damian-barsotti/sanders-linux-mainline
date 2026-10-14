#!/bin/sh
# Turn the display (tty1 console) on or off. Without an argument, toggle it.
#   display.sh on | off | status
L=/sys/class/backlight/backlight

status() {
    if [ "$(cat $L/bl_power)" = 0 ]; then echo on; else echo off; fi
}

action=${1:-toggle}
[ "$action" = toggle ] && { [ "$(status)" = on ] && action=off || action=on; }

case "$action" in
    on)     TERM=linux setterm --blank poke  < /dev/tty1 > /dev/tty1 ;;
    off)    TERM=linux setterm --blank force < /dev/tty1 > /dev/tty1 ;;
    status) ;;
    *)      echo "usage: $(basename "$0") [on|off|status]" >&2; exit 1 ;;
esac
echo "display: $(status)"
