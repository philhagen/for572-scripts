#!/bin/bash

TMPDIR=$( mktemp -d )

if [ -f /etc/sysconfig/geoip ]; then
    . /etc/sysconfig/geoip
fi

if [ ! -v GEOIP_LIBDIR ]; then
    GEOIP_LIBDIR=/usr/local/for572/share/GeoIP
fi

GEOIP_COUNTRYSOURCEFILE=GeoLite2-Country.tar.gz
GEOIP_CITYSOURCEFILE=GeoLite2-City.tar.gz
GEOIP_ASNSOURCEFILE=GeoLite2-ASN.tar.gz
GEOIP_BASEURL=https://geolite.maxmind.com/download/geoip/database
RUNNOW=0

# parse any command line arguments
if [ $# -gt 0 ]; then
    while true; do
        if [ $1 ]; then
            if [ $1 == '-now' ]; then
                RUNNOW=1
            fi
            shift
        else
            break
        fi
    done
fi

if [ ! -d ${GEOIP_LIBDIR} ]; then
    mkdir -p ${GEOIP_LIBDIR}
fi

if [ $RUNNOW -eq 0 ]; then
    # wait up to 20min to start, so all these VMs don't hit the server at the same exact time
    randomNumber=$RANDOM
    let "randomNumber %= 1800"
    sleep ${randomNumber}
fi

for i in ${GEOIP_COUNTRYSOURCEFILE} ${GEOIP_CITYSOURCEFILE} ${GEOIP_ASNSOURCEFILE}; do
    curl -s -o ${TMPDIR}/${i} ${GEOIP_BASEURL}/${i}
    tar xzf ${TMPDIR}/${i} -C ${TMPDIR}
done

find ${TMPDIR} -type f -name *.mmdb -exec mv {} ${GEOIP_LIBDIR}/ \;

rm -rf ${TMPDIR}
