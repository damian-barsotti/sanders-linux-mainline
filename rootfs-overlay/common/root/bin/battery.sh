#!/bin/sh
# Battery and charger status (pmi8994_fg and qcom-smbchg drivers).
B=/sys/class/power_supply/qcom-battery
U=/sys/class/power_supply/qcom-smbchg-usb

if [ ! -d "$B" ]; then
    echo "No battery driver (qcom-battery): this kernel lacks pmi8994_fg/qcom-smbchg."
    exit 1
fi

cur=$(( $(cat $B/current_now) / 1000 ))
if [ "$cur" -gt 0 ]; then dir="charging"; else dir="discharging"; fi
t=$(cat $B/temp)

printf "battery:      %s%%\n" "$(cat $B/capacity)"
printf "voltage:      %s V\n" "$(awk '{printf "%.3f", $1/1000000}' $B/voltage_now)"
printf "current:      %s mA (%s)\n" "$cur" "$dir"
printf "temperature:  %d.%d C\n" $((t / 10)) $((t % 10))
printf "health:       %s\n" "$(cat $B/health)"

if [ -d "$U" ]; then
    if [ "$(cat $U/online)" = 1 ]; then
        printf "charger:      connected %s, input limit %d mA\n" \
            "$(grep -oE '\[[A-Za-z]+\]' $U/usb_type)" $(( $(cat $U/input_current_limit) / 1000 ))
    else
        printf "charger:      disconnected\n"
    fi
    printf "charge max:   %d mA\n" $(( $(cat $U/constant_charge_current) / 1000 ))
fi
