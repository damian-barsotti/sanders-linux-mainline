#!/bin/sh
# Limite de corriente de entrada para cargar con un cable OTG en "Y".
#
# Con el cable en Y (cargador + periferico en el mismo micro-USB) las lineas de
# datos van al periferico, asi que la deteccion BC1.2 ve un puerto de datos
# (SDP) y qcom-smbchg fija 500 mA sin correr AICL. Con el cable en Y el camino
# de energia es bueno: a 1000 mA usbin queda firme en ~4.3-4.45 V y la bateria carga
# a ~+650-900 mA (pantalla apagada).
# Con un hub entre cargador y telefono NO conviene: el camino pierde tension y
# con mas de 500 mA VBUS oscila (medido 2026-10-07).
#
# Solo actua con SDP y rol USB host (adaptador/cable OTG). En modo device
# (cable a una PC) no se toca: un puerto USB 2.0 de PC solo garantiza 500 mA.
ILIM=1000000
U=/sys/class/power_supply/qcom-smbchg-usb

[ -d "$U" ] || exit 0
while true; do
    if [ "$(cat $U/online 2>/dev/null)" = 1 ] &&
       grep -q '\[SDP\]' $U/usb_type 2>/dev/null &&
       [ "$(cat /sys/class/usb_role/*/role 2>/dev/null)" = host ] &&
       [ "$(cat $U/input_current_limit)" != "$ILIM" ]; then
        echo "$ILIM" > $U/input_current_limit &&
            echo "cargador SDP con USB en modo host: limite de entrada $((ILIM / 1000)) mA"
    fi
    sleep 5
done
