#!/bin/sh

# USB input voltage, VPH_PWR (follows the battery) and USB role.
awk '{printf "usb input (usbin):   %.2f V\n", $1/1000000}' /sys/bus/iio/devices/iio:device*/in_voltage0_input
awk '{printf "power in (vph_pwr): %.3f V\n", $1/1000000}' /sys/bus/iio/devices/iio:device*/in_voltage7_input
echo "USB role: $(cat /sys/class/usb_role/*/role)"
