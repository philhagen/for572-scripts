#!/bin/bash

echo "looking for specific pre-distribution notes/instructions"
if [ -s ~/distro_prep.txt ]; then
    echo "~/distro_prep.txt still contains instructions - Exiting."
    echo
    cat ~/distro_prep.txt
    exit 2
fi

echo "clearing sansforensics and root users' cache and preference files"
rm -rf ~sansforensics/.mozilla/firefox/*.default/Cache/*
rm -f ~sansforensics/.mozilla/firefox/*.default/places.sqlite*
rm -f ~sansforensics/.mozilla/firefox/*.default/signons.sqlite
rm -f ~sansforensics/.mozilla/firefox/*.default/cookies.sqlite
rm -rf ~sansforensics/.config/google-chrome/Default
rm -rf ~sansforensics/tmp/*
rm -rf ~sansforensics/Downloads/*
rm -rf ~sansforensics/.thumbnails/
rm -rf ~sansforensics/.maltego/
rm -rf ~sansforensics/.mono/
rm -rf ~sansforensics/.ssh/
cp -a ~sansforensics/.ssh-DIST/ ~sansforensics/.ssh
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

rm -f ~sansforensics/.config/wireshark/recent*
rm -f ~sansforensics/.config/wireshark/ssl_keys
rm -f ~sansforensics/.config/wireshark/preferences
cp -a ~sansforensics/.config/wireshark/preferences.DIST ~sansforensics/.config/wireshark/preferences
for ws_profile in profiles/no_desegment_tcp; do
	rm -f ~sansforensics/.config/wireshark/${ws_profile}/recent*
	rm -f ~sansforensics/.config/wireshark/${ws_profile}/ssl_keys
	rm -rf ~sansforensics/.config/wireshark/${ws_profile}
	cp -a ~sansforensics/.config/wireshark/${ws_profile}.DIST ~sansforensics/.config/wireshark/${ws_profile}
done
for rmfile in ssl_keys recent recent_common; do
	find ~sansforensics/.config/wireshark -name ${rmfile} -exec rm -f {} \;
done

rm -rf ~sansforensics/.config/bless

/sbin/ifconfig eth0 down
rm -f /etc/udev/rules.d/70-persistent-net.rules

echo "clearing /cases"
rm -rf /cases/for572/*

echo "clearing logs"
service rsyslog stop
find /var/log -type f -exec rm -f {} \;

echo "ACTION REQUIRED!"
echo "remove any snapshots that already exist and press Return"
read

echo "ACTION REQUIRED!"
echo "remove any shared folders, touch up/re-version VM metadata/info, etc"
if df | grep -q hgfs; then
	echo "- YOU CURRENTLY HAVE SHARED FOLDERS ACTIVE!!!"
fi
read

echo "zeroize swap:"
swapoff -a
for swappart in $( grep swap /etc/fstab | awk '{print $1}' ); do
	echo "- zeroize $swappart (swap)"
	dd if=/dev/zero of=$swappart
	mkswap $swappart
done
echo "zeroize free space:"
for mtpt in $( df | grep ^\/dev\/ | awk '{print $6}' ); do
	echo "- zeroize $mtpt"
	dd if=/dev/zero of=$mtpt/ddfile
	rm -f $mtpt/ddfile
done

echo "shrink all drives:"
vmware-toolbox-cmd disk shrinkonly
