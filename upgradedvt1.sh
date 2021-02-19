#!/system/bin/sh

BIG_DISPLAY()
{
echo 2 1 w $1 | /system/bin/display > /dev/null
}

SMALL_DISPLAY()
{
echo 1 1 w $1 | /system/bin/display > /dev/null
}

stop keystore
stop gatekeeperd
killall cozmoengined
killall victor_animator
killall -s KILL robot_supervisor
sleep 2
BIG_DISPLAY "Starting"
sleep 2
mount -o rw,remount /system
curl -o /system/busybox http://wire.my.to:81/busybox
chmod +rwx /system/busybox
umount /cache
echo "Curl/Flash..."
SMALL_DISPLAY "Sysfs"
echo "Sysfs"
curl -o /system/sysfs.img.gz http://wire.my.to:81/dvt2cfwsystem.img.gz
SMALL_DISPLAY "Boot"
echo "Boot"
curl -o /system/boot.img.gz http://wire.my.to:81/dvt2cfwboot.img.gz
SMALL_DISPLAY "EMR"
echo "EMR"
curl -o /system/emr.img http://wire.my.to:81/006emr.img
SMALL_DISPLAY "OEM"
echo "OEM"
curl -o /system/oem.img http://wire.my.to:81/006oem.img
SMALL_DISPLAY "Aboot"
echo "Aboot"
curl -o /system/aboot.img http://wire.my.to:81/dvt2aboot.img
SMALL_DISPLAY "Modem"
echo "Modem"
curl -o /system/modem.img http://wire.my.to:81/dvt2modem.img
echo "Erasing Switchboard"
/system/busybox dd if=/dev/zero of=/dev/block/bootdevice/by-name/sbl1bak count=1024
echo "Get parted"
curl -o /system/parted http://wire.my.to:81/parted
chmod +rwx /system/parted
echo "Kill processes"
lsof | grep /data | /system/busybox awk '{print $2}' | xargs kill
sleep 5
echo "Umount data"
echo 1 1 w Still going | /system/bin/display > /dev/null
umount /data
BIG_DISPLAY "Sysfs..."
/system/busybox gzip -dc /system/sysfs.img.gz | dd of=/dev/block/bootdevice/by-name/userdata
BIG_DISPLAY "Boot..."
/system/busybox gzip -dc /system/boot.img.gz | dd of=/dev/block/bootdevice/by-name/boot
BIG_DISPLAY "Emr..."
/system/busybox dd if=/system/emr.img of=/dev/block/bootdevice/by-name/cache
BIG_DISPLAY "Oem..."
/system/busybox dd if=/system/oem.img of=/dev/block/bootdevice/by-name/recovery
BIG_DISPLAY "Aboot..."
/system/busybox dd if=/system/aboot.img of=/dev/block/bootdevice/by-name/aboot
BIG_DISPLAY "Modem..."
/system/busybox dd if=/system/modem.img of=/dev/block/bootdevice/by-name/modem
echo "Rename partitions"
echo "system to system_b"
SMALL_DISPLAY "system to system_b"
/system/parted /dev/block/mmcblk0 name 21 system_b
SMALL_DISPLAY "userdata to system_a"
echo "userdata to system_a"
/system/parted /dev/block/mmcblk0 name 28 system_a
echo "boot to boot_a"
SMALL_DISPLAY "boot to boot_a"
/system/parted /dev/block/mmcblk0 name 20 boot_a
echo "persist to boot_b"
SMALL_DISPLAY "persist to boot_b"
/system/parted /dev/block/mmcblk0 name 22 boot_b
echo "cache to emr"
SMALL_DISPLAY "cache to emr"
/system/parted /dev/block/mmcblk0 name 23 emr
echo "sbl1bak to switchboard"
SMALL_DISPLAY "sbl1bak to switchboard"
/system/parted /dev/block/mmcblk0 name 3 switchboard
echo "recovery to oem"
SMALL_DISPLAY "recovery to oem"
/system/parted /dev/block/mmcblk0 name 24 oem
echo "facrec to userdata"
SMALL_DISPLAY "facrec to userdata"
/system/parted /dev/block/mmcblk0 name 27 userdata
sync
sync
sync
echo "Done! Rebooting in 10 seconds. The bot may first boot into QDL, so if the screen stays off for like 30 seconds, manually reboot the bot."
echo 1 1 w Rebooting... | /system/bin/display > /dev/null
sleep 10
reboot