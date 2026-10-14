#!/bin/sh
# Restart the USB controller (dwc3 xHCI) when it dies.
#
# Unplugging a peripheral in host mode sometimes leaves the xHCI unresponsive
# ("xHCI host controller not responding, assume dead" / "HC died"), and nothing
# enumerates until it is restarted. Switching the USB role to device and back
# to host recovers it.
#
#   sanders-xhci-watchdog.sh             watch the kernel log
#   sanders-xhci-watchdog.sh --reset-now restart the controller once (test)

restart_xhci() {
    R=$(ls -d /sys/class/usb_role/* 2>/dev/null | head -1)
    [ -n "$R" ] || return 1
    echo "restarting the USB controller (device -> host)"
    echo device > "$R/role"
    sleep 3
    echo host > "$R/role"
    # The connector sets the role again from the ID pin: if no OTG adapter
    # is attached it goes back to device, which is correct.
}

if [ "$1" = --reset-now ]; then
    restart_xhci
    exit 0
fi

journalctl -k -f -n 0 -o cat | while IFS= read -r line; do
    case "$line" in
        *"HC died"*)
            echo "detected: $line"
            sleep 2
            restart_xhci ;;
    esac
done
