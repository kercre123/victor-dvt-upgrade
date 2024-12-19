#!/bin/bash

set -e

# script goal:
# download and hash check all the required images:
#  recoveryfs, recovery, emr, oem, aboot
# use parted (already in /cache) to shorten the huge system partition
# make emr and switchboard partitions with that new empty space
# dump all the images to respective partitions
# rename partitions so we have three slots

BASE_URL="http://wire.my.to:81"

EXPECTED_HASH_RFS="841d2cf6f7d9b6b0739f0074462b47e3"
EXPECTED_HASH_PARTED="54713d553be1194e91d530b7c03c7197"
EXPECTED_HASH_EMR="a6553e7b223b12a85809c957cfd3173c"
EXPECTED_HASH_OEM="54322f44b65e0e1db020ebacdf4f757f"
EXPECTED_HASH_ABOOT="1b447f29bcca755638ebbef56068aedf"
EXPECTED_HASH_REC="2f0ce78e70db21271974cf1fb7115439"

check_hash() {
    # usage: check_hash file expected_hash
    local file_path="$1"
    local expected_hash="$2"
    if [ ! -f "$file_path" ]; then
        echo "file not found: $file_path"
        exit 1
    fi
    local actual_hash
    actual_hash=$(md5sum "$file_path" | awk '{print $1}')
    if [ "$actual_hash" != "$expected_hash" ]; then
        echo "hash check failed for $file_path"
        echo "expected: $expected_hash"
        echo "actual:   $actual_hash"
        exit 1
    fi
}

download_file() {
    local dest="$1"
    local filename="$2"
    curl -o "$dest" "$BASE_URL/$filename"
}

BIG_DISPLAY()
{
    echo 2 1 w $1 | /system/bin/display > /dev/null
}

SMALL_DISPLAY()
{
    echo 1 1 w $1 | /system/bin/display > /dev/null
}

echo "mounting cache"
mount /dev/block/bootdevice/by-name/cache /cache
PATH=$PATH:/cache

SMALL_DISPLAY "start checks"

PARTED_FILE_PATH="/cache/parted"

if [ ! -f "$PARTED_FILE_PATH" ]; then
    echo "no parted found, downloading..."
    if command -v curl >/dev/null 2>&1; then
        download_file "$PARTED_FILE_PATH" "parted"
	chmod +x "$PARTED_FILE_PATH"
    else
        echo "curl missing"
        exit 1
    fi
    if [ ! -f "$PARTED_FILE_PATH" ]; then
        echo "download fail"
        exit 1
    fi
fi

if [ -f /dev/block/bootdevice/by-name/system_a ]; then
	echo "upgraded already"
	exit 0
fi

if [ -f /dev/block/bootdevice/by-name/emr ]; then
	echo "upgraded already"
	exit 0
fi

BIG_DISPLAY "preparing"
sleep 2
SMALL_DISPLAY "dirs"
mkdir -p /dvtupgrade
sleep 2
SMALL_DISPLAY "kill procs"
systemctl stop anki-robot.target
rm -rf /anki
sleep 2
SMALL_DISPLAY "download"
sleep 1
umount -f /factory
echo "curl files..."
BIG_DISPLAY "recoveryfs"
download_file "/dvtupgrade/recfs.img.gz" "wireos-recoveryfs.img.gz"

BIG_DISPLAY "recovery"
download_file "/dvtupgrade/rec.img.gz" "wireos-recovery.img.gz"

BIG_DISPLAY "emr"
download_file "/dvtupgrade/emr.img" "006emr.img"

BIG_DISPLAY "oem"
download_file "/dvtupgrade/oem.img" "006oem.img"

BIG_DISPLAY "aboot"
download_file "/dvtupgrade/aboot.img" "ankidev-nosigning.mbn"

BIG_DISPLAY "check files"

SMALL_DISPLAY "check rfs"
check_hash "/dvtupgrade/recfs.img.gz" "$EXPECTED_HASH_RFS"

SMALL_DISPLAY "check parted"
check_hash "$PARTED_FILE_PATH" "$EXPECTED_HASH_PARTED"
SMALL_DISPLAY "good"

SMALL_DISPLAY "check emr"
check_hash "/dvtupgrade/emr.img" "$EXPECTED_HASH_EMR"
SMALL_DISPLAY "good"

SMALL_DISPLAY "check oem"
check_hash "/dvtupgrade/oem.img" "$EXPECTED_HASH_OEM"
SMALL_DISPLAY "good"

SMALL_DISPLAY "check aboot"
check_hash "/dvtupgrade/aboot.img" "$EXPECTED_HASH_ABOOT"
SMALL_DISPLAY "good"

SMALL_DISPLAY "check recovery"
check_hash "/dvtupgrade/rec.img.gz" "$EXPECTED_HASH_REC"
SMALL_DISPLAY "good"

SMALL_DISPLAY "shortening system"
echo "shortening system"

# flexible in case we want to do the same for other partitions
# removes 32MB from system, makes two 16 MB partitions
line=$(parted -m /dev/mmcblk0 unit MB print | grep system)
num=$(echo $line | awk -F: '{print $1}')
start=$(echo $line | awk -F: '{print $2}' | sed 's/MB//')
end=$(echo $line | awk -F: '{print $3}' | sed 's/MB//')

newend=$((end - 32))
parted /dev/mmcblk0 resizepart $num ${newend}MB
# 32
parted /dev/mmcblk0 mkpart emr ext4 ${newend}MB $((newend+16))MB
# 33
parted /dev/mmcblk0 mkpart switchboard ext4 $((newend+16))MB $((newend+32))MB

SMALL_DISPLAY "begin flash"
sync

BIG_DISPLAY "recoveryfs..."
echo "dumping recoveryfs..."
gunzip -c "/dvtupgrade/recfs.img.gz" > "/dev/block/bootdevice/by-name/templabel"
BIG_DISPLAY "recovery..."
echo "dumping recovery..."
gunzip -c "/dvtupgrade/rec.img.gz" > "/dev/block/bootdevice/by-name/recoveryfs"
BIG_DISPLAY "emr..."
echo "dumping emr..."
dd if=/dvtupgrade/emr.img of=/dev/mmcblk0p32
BIG_DISPLAY "oem..."
echo "dumping oem..."
dd if=/dvtupgrade/oem.img of=/dev/block/bootdevice/by-name/oem
BIG_DISPLAY "aboot..."
echo "dumping aboot..."
dd if=/dvtupgrade/aboot.img of=/dev/block/bootdevice/by-name/aboot

sync

SMALL_DISPLAY "renaming"

echo "rename partitions"
BIG_DISPLAY "rn recovery"
parted /dev/mmcblk0 name 7 recovery
BIG_DISPLAY "rn recoveryfs"
parted /dev/mmcblk0 name 24 recoveryfs
BIG_DISPLAY "rn system_b"
parted /dev/mmcblk0 name 27 system_b
BIG_DISPLAY "rn system_a"
parted /dev/mmcblk0 name 30 system_a
BIG_DISPLAY "rn boot_a"
parted /dev/mmcblk0 name 23 boot_a
sync
echo "done, rebooting in 5 seconds."
SMALL_DISPLAY "done, reboot soon"
sleep 5
reboot
