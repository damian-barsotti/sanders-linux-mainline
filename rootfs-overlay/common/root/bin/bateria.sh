#!/bin/sh
# Estado de la bateria y del cargador (drivers pmi8994_fg y qcom-smbchg).
B=/sys/class/power_supply/qcom-battery
U=/sys/class/power_supply/qcom-smbchg-usb

if [ ! -d "$B" ]; then
    echo "No hay driver de bateria (qcom-battery): este kernel no tiene pmi8994_fg/qcom-smbchg."
    exit 1
fi

cur=$(( $(cat $B/current_now) / 1000 ))
if [ "$cur" -gt 0 ]; then dir="cargando"; else dir="descargando"; fi
t=$(cat $B/temp)

printf "bateria:      %s%%\n" "$(cat $B/capacity)"
printf "tension:      %s V\n" "$(awk '{printf "%.3f", $1/1000000}' $B/voltage_now)"
printf "corriente:    %s mA (%s)\n" "$cur" "$dir"
printf "temperatura:  %d.%d C\n" $((t / 10)) $((t % 10))
printf "salud:        %s\n" "$(cat $B/health)"

if [ -d "$U" ]; then
    if [ "$(cat $U/online)" = 1 ]; then
        printf "cargador:     conectado %s, limite de entrada %d mA\n" \
            "$(grep -oE '\[[A-Za-z]+\]' $U/usb_type)" $(( $(cat $U/input_current_limit) / 1000 ))
    else
        printf "cargador:     desconectado\n"
    fi
    printf "carga max:    %d mA\n" $(( $(cat $U/constant_charge_current) / 1000 ))
fi
