#!/bin/bash

while cat /sys/class/usb_role/*/role; lsusb; awk '{printf "usbin: %.2f V\n", $1/1000000}' /sys/bus/iio/devices/iio:device*/in_voltage0_input
do sleep 2
done
