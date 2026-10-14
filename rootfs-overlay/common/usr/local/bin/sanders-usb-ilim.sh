#!/bin/sh
# Input current limit for charging through an OTG "Y" cable.
#
# With a Y cable (charger and peripheral on the same micro-USB port) the data
# lines go to the peripheral, so BC1.2 detection sees a data port (SDP) and
# qcom-smbchg sets 500 mA without running AICL. The power path of a Y cable is
# good: at 1000 mA usbin stays at ~4.3-4.45 V and the battery charges at
# ~+650-900 mA (display off).
# Not suitable with a hub between the charger and the phone: the path drops
# too much voltage and VBUS oscillates above 500 mA.
#
# Only acts with an SDP charger and the USB role in host mode (OTG adapter or
# cable). Device mode (cable to a PC) is left alone: a USB 2.0 PC port only
# guarantees 500 mA.
ILIM=1000000
U=/sys/class/power_supply/qcom-smbchg-usb

[ -d "$U" ] || exit 0
while true; do
    if [ "$(cat $U/online 2>/dev/null)" = 1 ] &&
       grep -q '\[SDP\]' $U/usb_type 2>/dev/null &&
       [ "$(cat /sys/class/usb_role/*/role 2>/dev/null)" = host ] &&
       [ "$(cat $U/input_current_limit)" != "$ILIM" ]; then
        echo "$ILIM" > $U/input_current_limit &&
            echo "SDP charger with USB in host mode: input limit $((ILIM / 1000)) mA"
    fi
    sleep 5
done
