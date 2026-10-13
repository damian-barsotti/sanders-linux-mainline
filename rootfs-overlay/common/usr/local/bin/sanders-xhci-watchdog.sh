#!/bin/sh
# Reinicia el controlador USB (xHCI de la dwc3) si muere.
#
# Al desenchufar un periferico en modo host, a veces el xHCI deja de responder
# ("xHCI host controller not responding, assume dead" / "HC died") y no vuelve
# a detectar nada hasta reiniciarlo. Se recupera pasando el rol USB a device y
# de nuevo a host.
#
#   sanders-xhci-watchdog.sh             vigila el log del kernel
#   sanders-xhci-watchdog.sh --reset-now reinicia el controlador una vez (prueba)

reiniciar_xhci() {
    R=$(ls -d /sys/class/usb_role/* 2>/dev/null | head -1)
    [ -n "$R" ] || return 1
    echo "reiniciando el controlador USB (device -> host)"
    echo device > "$R/role"
    sleep 3
    echo host > "$R/role"
    # El rol host vuelve a pasarlo el conector segun el pin ID; si el
    # adaptador OTG no esta puesto, queda en device, que es lo correcto.
}

if [ "$1" = --reset-now ]; then
    reiniciar_xhci
    exit 0
fi

journalctl -k -f -n 0 -o cat | while IFS= read -r linea; do
    case "$linea" in
        *"HC died"*)
            echo "detectado: $linea"
            sleep 2
            reiniciar_xhci ;;
    esac
done
