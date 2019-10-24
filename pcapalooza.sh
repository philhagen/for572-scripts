#!/bin/bash
# (C)2019 Lewes Technology Consulting, LLC

# This script will traverse a directory tree full of pcap files and run a set 
#   of commands against each pcap file.
# As distributed, it's designed to handle the capstone data in FOR572, but you
#   can adjust it as needed for other situations.

# Set thsese two variables as needed.  Be mindful of the space available in
#   $DESTDIRROOT, as the commands below may require a LOT of disk space!
SOURCEPCAPS=/path/to/source/pcaps/
DESTDIRROOT=/cases/for572/capstone/
# Uncomment one or more of the annotated sections below, then run the script

for srcfile in $( find -L ${SOURCEPCAPS} -type f ); do
    echo
    echo "- processing ${srcfile}";

    directory=$( dirname ${srcfile#${SOURCEPCAPS}} );
    if [ ! -d ${DESTDIRROOT}/${directory} ]; then
        mkdir -p ${DESTDIRROOT}/${directory};
    fi
    filename=$( basename $srcfile );

    # Uncomment these three commands to process with Zeek
    # This will take a LONG time and require a LOT of disk space! You probably
    #   DO NOT want to do this to ALL the capstone pcaps!!
    #mkdir -p ${DESTDIRROOT}/${directory}/zeek_output/${filename};
    #cd ${DESTDIRROOT}/${directory}/zeek_output/${filename};
    #bro for572 -r ${srcfile};

    # Uncomment this one command to process with passivedns
    # This is a pretty manageable process
    #passivedns -r ${srcfile} -l ${DESTDIRROOT}/${directory}/passivedns.txt -L ${DESTDIRROOT}/${directory}/passivedns_nxdomain.txt

    # uncomment these two commands to process with nfpcapd
    # This is not needed for the FOR572 capstone, as you’ve been provided with
    #   NetFlow that covers well beyond the pcap data, but the command is here
    #   for your reference and future use as needed
    #mkdir -p ${DESTDIRROOT}/${directory}/netflow/${filename};
    #nfpcapd -r ${srcfile} -S 1 -z -l ${DESTDIRROOT}/${directory}/netflow/${filename};
done
