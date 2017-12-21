#!/bin/bash

if [ ! -z $SSH_CONN ]; then
    echo "ERROR! This script must be run locally, not via ssh."
    echo "quitting."
    exit 2
fi

if [ ! $UID == 0 ]; then
    echo "ERRO! This script must be run as root."
    echo "quitting."
    exit 2
fi

echo "looking for specific pre-distribution notes/instructions"
if [ -s ~/distro_prep.txt ]; then
    echo "~/distro_prep.txt still contains instructions - Exiting."
    echo
    cat ~/distro_prep.txt
    exit 2
fi

echo "updating for572-scripts git clone"
cd /usr/local/for572/src/for572-scripts
git pull

echo "clearing sansforensics and root users' cache and preference files"
rm -rf ~sansforensics/.mozilla/firefox/*.default/Cache/*
rm -f ~sansforensics/.mozilla/firefox/*.default/places.sqlite*
rm -f ~sansforensics/.mozilla/firefox/*.default/signons.sqlite
rm -f ~sansforensics/.mozilla/firefox/*.default/cookies.sqlite
rm -rf ~sansforensics/Downloads/*
rm -rf ~sansforensics/.mono/
rm -rf ~sansforensics/.ssh/
cp -a ~sansforensics/.ssh.DIST/ ~sansforensics/.ssh
rm -rf ~sansforensics/.cache/
rm -f ~sansforensics/.bash_history
rm -f ~sansforensics/.mysql_history
rm -f ~sansforensics/.scapy_history
rm -f ~sansforensics/.lesshst
rm -f ~sansforensics/.viminfo
rm -f ~sansforensics/.local/share/recently-used.xbel
rm -rf ~sansforensics/.local/share/zeitgeist/*sqlite*
rm -rf ~sansforensics/.local/share/gvfs-metadata/*
rm -rf ~sansforensics/for572-commands/
rm -f ~root/.bash_history
rm -f ~root/.mysql_history
rm -f ~root/.scapy_history
rm -f ~root/.lesshst
rm -f ~root/.viminfo
rm -rf ~root/.cache/
rm -rf  /usr/local/for572/NetworkMiner_*/AssembledFiles/*

for ws_profile in no_desegment_tcp; do
	rm -rf ~sansforensics/.config/wireshark/profiles/${ws_profile}
	cp -a ~sansforensics/.config/wireshark/profiles/${ws_profile}.DIST ~sansforensics/.config/wireshark/profiles/${ws_profile}
done
for rmfile in ssl_keys recent recent_common preferences; do
    rm -f ~sansforensics/.config/wireshark/${rmfile}
    if [ -f ~sansforensics/.config/wireshark/%{rmfile}.DIST ]; then
        cp -a ~sansforensics/.config/wireshark/${rmfile}.DIST ~sansforensics/.config/wireshark/${rmfile}
    fi
done

rm -rf ~sansforensics/.config/bless

/sbin/ifconfig ens33 down

echo "ensure /cases/for572/ only contains what is required from original evidence files"
read

echo "clearing logs"
service rsyslog stop
find /var/log -type f -exec rm -f {} \;

echo "ACTION REQUIRED!"
echo "remove any snapshots that already exist and press Return"
read

echo "ACTION REQUIRED!"
echo "remove any shared folders, touch up/re-version VM metadata/info, etc"
if df 2> /dev/null | grep -q hgfs; then
	echo "- YOU CURRENTLY HAVE SHARED FOLDERS ACTIVE!!!"
fi
read

echo "zeroize swap:"
for swappart in $( swapon --show --noheadings | awk '{print $1}' ); do
    swapuuid=$( swaplabel ${swappart} | awk '{print $2}' )
	echo "- zeroize $swappart (swap)"
    swapoff -U ${swapuuid}
	dd if=/dev/zero of=${swappart}
	mkswap ${swappart} -U ${swapuuid}
done

echo "shrink all drives:"
for shrinkpart in $( vmware-toolbox-cmd disk list ); do
    vmware-toolbox-cmd disk shrink ${shrinkpart}
done
