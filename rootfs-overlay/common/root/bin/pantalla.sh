#!/bin/sh
# Apaga o prende la pantalla (consola tty1). Sin argumento, alterna.
#   pantalla.sh on | off | estado
L=/sys/class/backlight/backlight

estado() {
    if [ "$(cat $L/bl_power)" = 0 ]; then echo encendida; else echo apagada; fi
}

accion=${1:-toggle}
[ "$accion" = toggle ] && { [ "$(estado)" = encendida ] && accion=off || accion=on; }

case "$accion" in
    on)     TERM=linux setterm --blank poke  < /dev/tty1 > /dev/tty1 ;;
    off)    TERM=linux setterm --blank force < /dev/tty1 > /dev/tty1 ;;
    estado) ;;
    *)      echo "uso: $(basename "$0") [on|off|estado]" >&2; exit 1 ;;
esac
echo "pantalla: $(estado)"
