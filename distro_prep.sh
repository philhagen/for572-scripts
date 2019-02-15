#!/bin/bash

DISKSHRINK=1
CASERELOAD=1
# parse any command line arguments
if [ $# -gt 0 ]; then
    while true; do
        if [ "$1" ]; then
            if [ "$1" == '-nodisk' ]; then
                DISKSHRINK=0
            elif [ "$1" == '-nocases' ]; then
                CASERELOAD=0
            fi
            shift
        else
            break
        fi
    done
fi

if [ ! -z $SSH_CONN ]; then
    echo "ERROR! This script must be run locally, not via ssh."
    echo "quitting."
    exit 2
fi

if [ ! $UID == 0 ]; then
    echo "ERROR! This script must be run as root."
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

echo "updating for572 command line text files"
su - sansforensics -c /usr/local/for572/bin/for572-getcommands.sh


echo "clearing sansforensics and root users' cache and preference files"
rm -rf ~sansforensics/.mozilla/firefox/*.default/Cache/*
rm -f ~sansforensics/.mozilla/firefox/*.default/places.sqlite*
rm -f ~sansforensics/.mozilla/firefox/*.default/signons.sqlite
rm -f ~sansforensics/.mozilla/firefox/*.default/cookies.sqlite
rm -f ~sansforensics/.config/chromium/
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
rm -f ~sansforensics/.recently-used
rm -f ~sansforensics/.wget-hsts
rm -rf ~sansforensics/.local/share/zeitgeist/*sqlite*
rm -rf ~sansforensics/.local/share/gvfs-metadata/*
rm -f ~root/.bash_history
rm -f ~root/.mysql_history
rm -f ~root/.scapy_history
rm -f ~root/.lesshst
rm -f ~root/.viminfo
rm -rf ~root/.cache/
rm -f ~root/.wget-hsts
rm -rf  /usr/local/for572/NetworkMiner_*/AssembledFiles/*
mkdir -m 1777 /usr/local/for572/NetworkMiner/AssembledFiles/cache/

for ws_profile in no_desegment_tcp; do
    rm -rf ~sansforensics/.config/wireshark/profiles/${ws_profile}
    cp -a ~sansforensics/.config/wireshark/profiles/${ws_profile}.DIST ~sansforensics/.config/wireshark/profiles/${ws_profile}
done
for rmfile in ssl_keys recent recent_common preferences; do
    rm -f ~sansforensics/.config/wireshark/${rmfile}
    if [ -f ~sansforensics/.config/wireshark/${rmfile}.DIST ]; then
        cp -a ~sansforensics/.config/wireshark/${rmfile}.DIST ~sansforensics/.config/wireshark/${rmfile}
    fi
done

rm -rf ~sansforensics/.config/bless

/sbin/ifconfig ens33 down

if [ $CASERELOAD -eq 1 ]; then
    if [ ! -d /mnt/hgfs/sample_pcaps/ -o ! -d /mnt/hgfs/lab_data/ ]; then
        echo "ERROR: Required source directories in /mnt/hgfs/ are not availalble - exiting."
        exit 2
    fi
    labs='demo-01 lab-1.2 lab-2.1 lab-2.2 lab-3.2 lab-3.3 lab-4.1 lab-4.2 lab-5.1 lab-5.2 lab-5.3'
    placeholder_labs='capstone lab-1.1 lab-2.3 lab-3.1 lab-4.3'
    echo "ensure /cases/for572/ only contains what is required from original evidence files"
    echo "will do this automatically, but need to ensure source data is available at /mnt/hgfs/lab_data/ before proceeding"
    read
    rm -rf /cases/for572/*

    mkdir /cases/for572/sample_pcaps/
    cd /cases/for572/sample_pcaps/
    cp -a /mnt/hgfs/sample_pcaps/* ./

    for lab in $labs; do
        cd /cases/for572/
        mkdir $lab
        cd /cases/for572/$lab/
        unzip /mnt/hgfs/lab_data/${lab}_source_evidence.zip
    done

    for placeholder in $placeholder_labs; do
        cd /cases/for572/
        mkdir $placeholder
        cd /cases/for572/$placeholder/
        cp -a /mnt/hgfs/lab_data/placeholders/${placeholder}_readme.txt ./
    done

    cd /cases/for572/
    chown -R sansforensics:sansforensics /cases/for572/*
fi

echo "clearing logs"
service rsyslog stop
find /var/log -type f -exec rm -f {} \;

echo "ACTION REQUIRED!"
echo "remove any shared folders, touch up/re-version VM metadata/info, etc"
if df 2> /dev/null | grep -q hgfs; then
    echo "- YOU CURRENTLY HAVE SHARED FOLDERS ACTIVE!!!"
fi
read

if [ $DISKSHRINK -eq 1 ]; then
    echo "ACTION REQUIRED!"
    echo "remove any snapshots that already exist and press Return"
    read

    echo "zeroize swap:"
    for swappart in $( swapon --show --noheadings | awk '{print $1}' ); do
        swapuuid=$( swaplabel ${swappart} | awk '{print $2}' )
        echo "- zeroize $swappart (swap)"
        swapoff -U ${swapuuid}
        dd if=/dev/zero of=${swappart}
        mkswap ${swappart} -U ${swapuuid}
    done

    echo "zeroize disks:"
    for diskpart in $( mount | grep -e "xfs\|ext[234]" | awk '{print $3}' | grep -v ^\/var\/lib\/docker\/aufs$ ); do
        echo "- zeroize ${diskpart}"
        dd if=/dev/zero of=${diskpart}/ddfile
        rm -f ${diskpart}/ddfile
    done
fi

echo "shrink all drives:"
for shrinkpart in $( vmware-toolbox-cmd disk list ); do
    vmware-toolbox-cmd disk shrink ${shrinkpart}
done
