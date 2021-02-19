#!/bin/bash
#dvt2 upgrading, no usb

set -e

echo "Mount cache"
mount /dev/block/bootdevice/by-name/cache /cache

echo "Checking if parted exists"
if [ ! -f /cache/parted ]; then
	echo "/cache/parted does not exist."
	exit 0
fi

echo "Checking if this is a DVT2 partition table"
if [ -f /dev/block/bootdevice/by-name/system_a ]; then
	echo "This partition table is already upgraded fool"
	exit 0
fi

echo "Stop anki-robot.target"
systemctl stop anki-robot.target
echo "Remove anki"
rm -rf /anki
umount -f /factory
echo "Curl/Flash..."
echo 2 1 w Upgrading | /system/bin/display > /dev/null
echo "Sysfs"
curl -o - http://wire.my.to:81/dvt2cfwsystem.img.gz | gunzip > /dev/block/bootdevice/by-name/templabel
echo "Boot"
curl -o - http://wire.my.to:81/dvt2cfwboot.img.gz | gunzip > /dev/block/bootdevice/by-name/boot
echo "EMR"
curl -L http://wire.my.to:81/006emr.img | dd of=/dev/block/bootdevice/by-name/recoveryfs
echo "OEM"
curl -L http://wire.my.to:81/006oem.img | dd of=/dev/block/bootdevice/by-name/oem
echo "Erasing Switchboard"
dd if=/dev/zero of=/dev/block/bootdevice/by-name/sbl1bak count=1024
echo "Rename partitions"
echo "system to system_b"
/cache/parted /dev/mmcblk0 name 30 system_b
echo "templabel to system_a"
/cache/parted /dev/mmcblk0 name 24 system_a
echo "boot to boot_a"
/cache/parted /dev/mmcblk0 name 23 boot_a
echo "recoveryfs to emr"
/cache/parted /dev/mmcblk0 name 7 emr
echo "sbl1bak to switchboard"
/cache/parted /dev/mmcblk0 name 3 switchboard
sync
echo "Done! Rebooting in 10 seconds. The bot may first boot into QDL, so if the screen stays off for like 30 seconds, manually reboot the bot."
echo 1 1 w Done | /system/bin/display > /dev/null
sleep 10
reboot