#!/bin/bash

DISKSHRINK=1
CASERELOAD=1

labs='demo-01 lab-1.2 lab-2.1 lab-2.2 lab-3.2 lab-3.3 lab-4.1 lab-4.2 lab-5.1 lab-5.2 lab-5.3'
placeholder_labs='capstone lab-1.1 lab-2.3 lab-3.1 lab-4.3'

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
echo

echo "Please confirm the ~sansforensics/.ssh/* files are correct and free of detritus."
echo "Press return if you've completed this."
read
echo

if [ $CASERELOAD -eq 1 ]; then
    if [ ! -d /mnt/hgfs/sample_pcaps/ -o ! -d /mnt/hgfs/lab_data/ ]; then
        echo "ERROR: Required source directories in /mnt/hgfs/ are not availalble - exiting."
        exit 2
    fi
fi

echo "updating for572-scripts git clone"
cd /usr/local/for572/src/for572-scripts
su - sansforensics -c "git pull"

echo "updating for572 workbook"
su - sansforensics -c "bash /var/www/html/workbook/resources/workbook-update.sh"

echo "clearing sansforensics and root users' preference files"
sudo -u sansforensics bleachbit -c firefox.* chromium.* bash.history gnome.* system.cache system.recent_documents system.trash
bleachbit -c apt.* bash.history system.rotated_logs
rm -rf ~sansforensics/Downloads/*
rm -rf ~sansforensics/.mono/
rm -f ~sansforensics/.mysql_history
rm -f ~sansforensics/.scapy_history
rm -f ~sansforensics/.lesshst
rm -f ~sansforensics/.viminfo
rm -f ~sansforensics/.wget-hsts
rm -rf ~sansforensics/.local/share/Trash/*
rm -rf ~sansforensics/.local/share/ijq/
rm -rf /cases/.Trash*
rm -f ~root/.mysql_history
rm -f ~root/.scapy_history
rm -f ~root/.lesshst
rm -f ~root/.viminfo
rm -rf ~root/.cache/
rm -f ~root/.wget-hsts
rm -rf  /usr/local/for572/NetworkMiner_*/AssembledFiles/*
rm -f /etc/GeoIP.conf
rm -f /var/spool/mail/*
mkdir -m 1777 /usr/local/for572/NetworkMiner/AssembledFiles/cache/

echo "resetting Wireshark profiles"
#for ws_profile in no_desegment_tcp; do
#    rm -rf ~sansforensics/.config/wireshark/profiles/${ws_profile}
#    cp -a ~sansforensics/.config/wireshark/profiles/${ws_profile}.DIST ~sansforensics/.config/wireshark/profiles/${ws_profile}
#done
for rmfile in rsa_keys recent recent_common preferences enabled_protos maxmind_db_paths ssl_keys; do
    rm -f ~sansforensics/.config/wireshark/${rmfile}
    if [ -f ~sansforensics/.config/wireshark/${rmfile}.DIST ]; then
        cp -a ~sansforensics/.config/wireshark/${rmfile}.DIST ~sansforensics/.config/wireshark/${rmfile}
    fi
done

echo "Resetting GeoIP data"
for GEOIPDB in ASN City Country; do
    rm -f /usr/local/for572/share/GeoIP/GeoLite2-${GEOIPDB}.mmdb
    curl -s -L -o /usr/local/for572/share/GeoIP/GeoLite2-${GEOIPDB}.mmdb https://lewestech.com/dist/GeoLite2-${GEOIPDB}.mmdb
    chmod 644 /usr/local/for572/share/GeoIP/GeoLite2-${GEOIPDB}.mmdb
done
rm -f /etc/cron.d/geoipupdate

/sbin/ifconfig ens33 down

if [ $CASERELOAD -eq 1 ]; then
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
        shred -n 0 -z -v ${swappart}
        mkswap ${swappart} -U ${swapuuid}
    done

    echo "zeroize disks:"
    for diskpart in $( mount | grep -e "xfs\|ext[234]" | awk '{print $3}' | grep -v ^\/var\/lib\/docker\/aufs$ ); do
        echo "- zeroize ${diskpart}"
        dd if=/dev/zero of=${diskpart}/ddfile
        rm -f ${diskpart}/ddfile
    done

    echo "shrink all drives:"
    for shrinkpart in $( vmware-toolbox-cmd disk list ); do
        vmware-toolbox-cmd disk shrink ${shrinkpart}
    done
fi
