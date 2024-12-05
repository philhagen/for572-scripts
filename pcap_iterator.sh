#!/bin/bash
# (C)2024 Lewes Technology Consulting, LLC

# This script will traverse a directory tree full of pcap files and run a set 
#   of commands against each pcap file.
# As distributed, it's designed to handle the capstone data in FOR572, but you
#   can adjust it as needed for other situations.

# Set these two variables as needed.  Be mindful of the space available in
#   $DEST_DIR_ROOT, as the commands below may require a LOT of disk space.
SOURCE_PCAPS="/path/to/source/pcaps/"
DEST_DIR_ROOT="/cases/for572/capstone/"

if [ $UID == 0 ]; then
    echo "WARNING! You're running this script as root (directly or with sudo)."
    echo "         This may not be intended - since most evidence access should be done"
    echo "         with user-level permissions."
    echo "         Press Ctrl-C to terminate if you don't REALLY need to run this as root"
    echo "         or press Return to continue if you truly know what you're doing."
    echo
    echo "   Hint: For all uses in FOR572 courseware, you DO NOT need to run this as root!"
    read
fi

# Uncomment one or more of the annotated sections below, then run the script
for src_file in $( find -L ${SOURCE_PCAPS} -type f ); do
    echo "- processing ${src_file}"

    directory=$( dirname ${src_file#${SOURCE_PCAPS}} )
    filename=$( basename $src_file )
    if [ ! -d ${DEST_DIR_ROOT}/${directory} ]; then
        mkdir -p ${DEST_DIR_ROOT}/${directory}
    elif [ ! -w ${DEST_DIR_ROOT}/${directory} ]; then
        echo "ERROR: Destination subdirectory ${DEST_DIR_ROOT}/${directory} exists but is not writable."
        echo "Exiting."
        exit 2
    fi

###### TCPDUMP ######
    # Uncomment the following four commands.
    # Change the following two variable assignments to reflect the pcap
    #   reduction you require
    # $TRAFFIC_TYPE is a cosmetic label that will be prepended to the output
    #   filenames
    # $BPF is the filter to apply.  Be careful, as this could result in a LOT
    #   of space.
    # After running this sequence, you will likely want to use mergecap or
    #   something similar to unify the resulting files.
    #TRAFFIC_TYPE=NFURY_MYSQL
    #BPF='host 172.16.7.15 and tcp and port 3306'
    #mkdir -p ${DEST_DIR_ROOT}/$directory/tcpdump_reduced
    #tcpdump -n -s 0 -r ${src_file} -w ${DEST_DIR_ROOT}/${directory}/tcpdump_reduced/${TRAFFIC_TYPE}_${filename} ${BPF}

###### TRIMPCAP ######
    # Uncomment the following two commands.
    # $TRIM_LENGTH is an integer for the maximum number of bytes per flow that will be retained
    # WARNING WARNING WARNING: The trimpcap.py command OVERWRITES the source file so be sure you don't need the original data
    # THERE IS NO UNDO BUTTON HERE!!!!!
    #$TRIM_LENGTH=30280
    #trimpcap.py $TRIM_LENGTH ${src_file}

###### ZEEK ######
    # Uncomment the following two commands to create an output directory for
    #   each input pcap file, as required for Zeek processing
    #mkdir -p ${DEST_DIR_ROOT}/${directory}/zeek_output/${filename}
    #cd ${DEST_DIR_ROOT}/${directory}/zeek_output/${filename}

    # Uncomment this command to process with Zeek, using the for572 policy
    #zeek for572 -r ${src_file} 2> /dev/null

    # Uncomment this command to process with Zeek, using the for572-allfiles
    #   policy
    # This will take a LONG time and require a LOT of disk space! You probably
    #   DO NOT want to do this to ALL the capstone pcaps!!
    #zeek for572-allfiles -r ${src_file} 2> /dev/null

    # compress the log files just created before moving on
    #gzip -f *.log

###### PASSIVEDNS ######
    # Uncomment this one command to process with passivedns
    # This is a pretty manageable process
    #passivedns -r ${src_file} -l ${DEST_DIR_ROOT}/${directory}/passivedns.txt -L ${DEST_DIR_ROOT}/${directory}/passivedns_nxdomain.txt

###### NFCAPD ######
    # Uncomment these two commands to process with nfpcapd
    # This is not needed for the FOR572 capstone, as you’ve been provided with
    #   NetFlow that covers well beyond the pcap data, but the command is here
    #   for your reference and future use as needed
    #mkdir -p ${DEST_DIR_ROOT}/${directory}/netflow/${filename}
    #nfpcapd -r ${src_file} -S 1 -z -l ${DEST_DIR_ROOT}/${directory}/netflow/${filename}

done
