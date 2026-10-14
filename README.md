# sanders-linux-mainline

**Mainline Linux + Arch Linux ARM on a real Motorola Moto G5S Plus (`sanders`, Snapdragon 625 / MSM8953).**

This is a fork of [rtyker/sanders-linux-mainline](https://github.com/rtyker/sanders-linux-mainline).
The upstream port was validated on a Moto G5 Plus (`potter`), and its build does not boot on a
`sanders`. This branch adds the fixes needed on real `sanders` hardware: kernel size, panel
driver, battery charging, USB OTG and a usable console. It was tested on two phones, XT1804
(64 GB) and XT1805 (32 GB), running the headless rootfs from the eMMC with no PC attached.

The original Portuguese README, which describes the upstream port and its `potter` results, is
in [`docs/README.pt-BR.md`](docs/README.pt-BR.md).

## Status on a real sanders

| Component | Status | Notes |
| :--- | :---: | :--- |
| Standalone boot from eMMC | ✅ | lk2nd in `boot` → extlinux in `cache` (ext2) → kernel → Arch Linux ARM in `userdata`. TWRP can stay in `recovery`. |
| Display | ✅ | Tianma 5.5" NT35596 panel (`mot_tianma_550_1080p_vid_v0`) with a dedicated driver. Text console with a 20x40 font. |
| Wi-Fi (WCN3680B) | ✅ | Client mode, WPA2. SSH over Wi-Fi. |
| USB gadget | ✅ | Serial console (`/dev/ttyACM0` on the PC) and USB network (phone at `10.42.0.2`). |
| Bluetooth | ✅ | Tested with a Bluetooth keyboard. |
| USB OTG host | ✅ | Role selected automatically by the micro-USB ID pin. USB serial drivers (CDC ACM, CH340, FTDI, CP210x, PL2303) are built in. |
| Battery charging | ✅ | PMI8950 charger and fuel gauge drivers (see [Charging](#charging)). |
| PMIC ADC | ✅ | USB input voltage and VPH_PWR in `/sys/bus/iio`. |
| Not tested on sanders | — | GPU acceleration, audio, touchscreen, camera, sensors, desktop flavors. |

The DJN panel variant (ILI7807D) found in some `sanders` units has no driver yet.

## Fixes over upstream

- **Kernel size:** lk2nd on MSM8953 loads the DTB at DDR+52 MB, and its extlinux path caps the
  kernel at 50 MB. The arm64 defconfig produced a 56 MB image that overwrote the DTB, and the
  phone reset about 11 s after boot with no log. Every non-Qualcomm `CONFIG_ARCH_*` is disabled,
  which brings the image to about 41 MB. After changing the kernel config, check that
  `image_size` (offset 16 in the arm64 Image header) stays under 50 MB.
- **Panel:** the `sanders` uses a Tianma NT35596 panel, not the `potter` one. `kernel/0008` adds a
  driver generated from the stock device tree. The DTS uses
  `compatible = "motorola,sanders-panel"`, which lk2nd replaces with the detected panel.
  `qcom,cabc` is removed from the WLED node; with CABC enabled the screen stays black.
- **Battery charging:** mainline has no PMI8950 charger driver, so the battery never charges.
  `kernel/0009` adds the `qcom-smbchg` charger and `pmi8994_fg` fuel gauge drivers from
  [msm8953-mainline/linux](https://github.com/msm8953-mainline/linux) (branch `7.1.3/main`).
- **USB OTG:** `dr_mode = "otg"` plus a `gpio-usb-b-connector` on the ID pin (GPIO 59).
- **PMIC VADC:** built into the kernel, with the PM8953 VPH_PWR channel added.
- **Rootfs overlay:** `05-build-rootfs.sh` copied the overlay with `cp -a`, which left `/`,
  `/etc` and `/usr` owned by the `alarm` user. The overlay is now copied as root.
- **Console:** 20x40 font, `us-acentos` keymap (US international with dead keys), quiet boot,
  and automatic blanking after 5 minutes.

## Building (Ubuntu 22.04)

`scripts/00-setup-host.sh` targets Arch Linux. On Ubuntu 22.04, install:

```bash
sudo apt install gcc-arm-none-eabi binutils-arm-none-eabi gcc-aarch64-linux-gnu flex bison \
    ccache libelf-dev device-tree-compiler mkbootimg libarchive-tools arch-install-scripts \
    qemu-user-static
```

`python3-libfdt` does not exist on Ubuntu 22.04. If a tool needs `pylibfdt`, install it in a
Python virtualenv with pip.

### Proprietary firmware

The firmware blobs are not in the repository (`firmware/` is gitignored). Each user extracts them
from their own phone and places them in `firmware/` before building the initramfs and rootfs:

| File(s) | Source |
| :--- | :--- |
| `wcnss.*`, `adsp.*` | `image/` directory of the `modem` partition (a FAT image) |
| `qcom/msm8953/motorola/sanders/a506_zap.*` | `modem` partition (`a506_zap.*`) |
| `a530/a530_pfp.fw`, `a530/a530_pm4.fw` | [linux-firmware](https://gitlab.com/kernel-firmware/linux-firmware) (`qcom/`) |
| `wlan/prima/WCNSS_qcom_wlan_nv.bin` | Stock Android `system` partition, `/system/etc/firmware/wlan/prima/` |

`scripts/09-extract-firmware.sh` can do this from a stock flashfile zip.

### Build steps

Run from the repository root:

```bash
./scripts/01-build-lk2nd.sh
./scripts/02-build-kernel.sh
./scripts/03-build-busybox.sh
./scripts/04-build-initramfs.sh
sudo FLAVOR=headless ./scripts/05-build-rootfs.sh
./scripts/06-build-boot.sh
```

The outputs are `build/out/lk2nd.img`, `build/out/boot-cache.img` (kernel, DTB, initramfs and
`extlinux.conf` in a 256 MB ext2 image), `build/out/boot-sanders.img` (for a temporary
`fastboot boot`) and `build/rootfs-arch-headless.img`.

## Installing

> ⚠️ This erases Android: `userdata` is overwritten with the Linux rootfs. Back up anything you
> need first.

What we used and tested: an unlocked bootloader with TWRP in `recovery`.

1. **Back up the partitions** from TWRP, at least `boot`, `recovery`, `modem`, `modemst1`,
   `modemst2`, `fsg`, `fsc` and `persist`. For example:

   ```bash
   for p in boot recovery modem modemst1 modemst2 fsg fsc persist; do
       adb exec-out "dd if=/dev/block/bootdevice/by-name/$p" > backup/$p.img
   done
   ```

2. **Install lk2nd in `boot`** from TWRP:

   ```bash
   adb push build/out/lk2nd.img /tmp/
   adb shell dd if=/tmp/lk2nd.img of=/dev/block/bootdevice/by-name/boot
   adb reboot
   ```

   `scripts/99-flash-rootfs-final.sh` also writes lk2nd to `recovery`. If you want to keep TWRP,
   flash the partitions by hand instead.

3. **Enter lk2nd fastboot:** hold **Volume Down** while the phone powers on. Then flash the boot
   partition and the rootfs:

   ```bash
   fastboot flash cache build/out/boot-cache.img
   fastboot flash userdata build/rootfs-arch-headless.img
   fastboot reboot
   ```

From then on the phone boots Linux by itself. To get back to TWRP, power on with
**Volume Down + Power** to reach the Motorola bootloader, then select Recovery.

To power off from the lk2nd menu, choose "Shutdown" with the USB cable unplugged; with a cable
attached the phone powers on again.

## First boot

- The display shows a root console with autologin.
- **Wi-Fi:** `sanders-network-setup.sh wifi <SSID> -` prompts for the password without leaving it
  in the shell history or the process list.
- **SSH:** only key authentication is allowed. Add your public key with `sanders-ssh-setup.sh`,
  from the display console or the USB serial console (`picocom -b 115200 /dev/ttyACM0` on the
  PC).
- **USB network:** the phone is `10.42.0.2`. Give the PC `10.42.0.1/24` on the USB network
  interface, for example with a NetworkManager connection in "shared" mode, or with
  `scripts/08-host-net.sh`.
- **Change the default passwords** of Arch Linux ARM (`root`/`root`, `alarm`/`alarm`). The
  display and serial consoles log in as root without a password.
- To install packages, run a full `pacman -Syu` first: the package database in the image is old
  and package downloads fail with 404.

## Updating the kernel

- **Permanent:** copy `Image.gz` and the DTB to the `cache` partition from the running system and
  reboot:

  ```bash
  mount /dev/disk/by-label/boot /mnt     # files are under /mnt/boot/
  ```

  Keep the previous files (for example as `.prev`) so you can restore them from TWRP. You can
  also reflash the whole partition from lk2nd fastboot with
  `fastboot flash cache build/out/boot-cache.img`.
- **Temporary test:** hold **Volume Down** at power on to reach lk2nd fastboot, then
  `fastboot boot build/out/boot-sanders.img`.

## Charging

Charging works with `qcom-smbchg`. Status is in `/sys/class/power_supply/qcom-battery` and
`/sys/class/power_supply/qcom-smbchg-usb`; `~/bin/bateria.sh` prints a summary.

- The battery is configured at 4.35 V float, 1 A charge current and 150 mA termination (the
  stock values are 4.40 V and 3 A), to be gentle with aged batteries left on a charger.
- With a wall charger detected as DCP, AICL raises the input limit up to 3 A. Measured: about
  +1 A into the battery.
- When a charger is seen as a data port (SDP), the driver keeps a 500 mA input limit. The display
  alone draws about 320 mA; it blanks after 5 minutes, and `~/bin/pantalla.sh on|off` controls
  it.
- **Charging in host mode:** the phone does not supply VBUS to peripherals. To use USB
  peripherals and charge at the same time, use an **OTG Y cable with a power input**. The
  `sanders-usb-ilim` service raises the input limit to 1 A in that case (SDP charger with the USB
  role in host mode). Measured with the display off: +650 to +900 mA into the battery.
- **Powered hubs are not a good charging path:** the voltage drop over the hub, cable and adapter
  makes VBUS oscillate above 500 mA, and charging falls to almost nothing.
- Fuel gauge quirks: `status` can say "Charging" while discharging (trust the sign of
  `current_now`), and `current_now` sometimes reads exactly 0 (ignore those samples).

## Known issues

- No VBUS output in host mode: the OTG boost regulator (`otg-vbus` in `qcom-smbchg`) is not wired
  in the DT yet. Bus-powered peripherals need a powered hub or a Y cable.
- Unplugging a peripheral in host mode can kill the xHCI controller ("HC died"). The
  `sanders-xhci-watchdog` service detects it and restarts the controller.
- The upstream audio, GPU and desktop flavor work has not been verified on a `sanders`.

## Helper scripts

Installed in `/root/bin` (on the `PATH`). Their names and output are in Spanish:

| Script | Purpose |
| :--- | :--- |
| `bateria.sh` | Battery level, voltage, current, temperature, charger type and input limit. |
| `energia.sh` | USB input voltage, VPH_PWR and USB role. |
| `pantalla.sh on\|off\|estado` | Turn the display on or off, or show its state. |
| `test_usb_hub_otg.sh` | Loop over the USB role, `lsusb` and USB input voltage, to test OTG hubs. |

## License and credits

- Upstream port: [rtyker/sanders-linux-mainline](https://github.com/rtyker/sanders-linux-mainline).
- Charger and fuel gauge drivers: [msm8953-mainline/linux](https://github.com/msm8953-mainline/linux).
- Panel driver generated with
  [linux-mdss-dsi-panel-driver-generator](https://github.com/msm8916-mainline/linux-mdss-dsi-panel-driver-generator).
- Bootloader: [lk2nd](https://github.com/msm8916-mainline/lk2nd).
- Linux kernel and the scripts, tools and documentation in this repository: GPL-2.0.
- Base DTS: Sireesh Kodali's `msm8953-motorola-potter.dts` (BSD-3-Clause).
