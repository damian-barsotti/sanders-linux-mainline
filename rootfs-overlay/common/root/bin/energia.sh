#!/bin/sh

# Tension de entrada USB, VPH_PWR (sigue a la bateria) y rol del USB.
awk '{printf "usb input (usbin):   %.2f V\n", $1/1000000}' /sys/bus/iio/devices/iio:device*/in_voltage0_input
awk '{printf "power in (vph_pwr): %.3f V\n", $1/1000000}' /sys/bus/iio/devices/iio:device*/in_voltage7_input
echo "rol USB: $(cat /sys/class/usb_role/*/role)"
