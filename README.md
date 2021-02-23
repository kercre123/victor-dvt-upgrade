# victor-dvt-upgrade

This is a set of scripts which upgrades pre-modern-partition-table bots.

## disclaimer

I am not responsible for bricks. If something goes wrong, and the bot won't boot, your best hope will be Qualcomm Download Mode through USB. 

When the bot shutdowns and doesn't boot up at the end of the script, it can be scary, so make sure you read the instructions and reboot manually again before going to me.

## upgradedvt2.sh

This script upgrades a DVT2 bot. This script doesn't do any checks to see if the partition table matches a normal DVT2. Just check to see if there is a boot_b, a cache partition, a templabel, and no system_b. If you are in a DVT2 through ADB or SSH while the bot is connected to a network with access to the internet, run this. NOTE: After the bot reboots on his own, the screen will likely stay off. You will need to reboot the bot again manually.

`curl http://wire.my.to:81/upgradedvt2.sh | /bin/bash`

## upgradedvt1.sh/upgradedvt1init.sh

These scripts upgrade an Android DVT1 bot. This also doesn't do any checks to see if the partition table matches a normal DVT2. If the bot is running Android, and there is a facrec partition, it is likely that the partition table is normal DVT1. These bots take a little more work to get connected to wifi. Best bet is to change your subnet mask/ip range to allow 192.168.40.* addresses. If you get in through adb shell, run the command below. NOTE: After the bot reboots on his own, the screen will likely stay off. You will need to reboot the bot again manually.

`curl http://wire.my.to:81/upgradedvt1init.sh | /system/bin/sh`

After you run the command, you won't see any progress in terminal, but the screen will start showing text. The script is daemonized because Wi-Fi will disconnect in the middle. The upgradedvt1init.sh script curls the main script and daemonizes it.




