#!/bin/bash
# (C)2026 Lewes Technology Consulting, LLC

# This script traverses a directory tree full of pcap files and runs a
#   user-selected sequence of commands against each pcap file.
# As distributed, it's designed to handle the capstone data in FOR572, but you
#   can adjust it as needed for other situations.

################################################################################
# Set these two variables as needed.  Be mindful of the space available in
#   ${DEST_DIR_ROOT}, as the commands below may require a LOT of disk space.
SOURCE_PCAPS="/path/to/source/pcaps/"
DEST_DIR_ROOT="/cases/for572/capstone/"

# Set these variables to determine which processing to perform
# After processing with tcpdump, you will likely want to use mergecap or similar to unify the resulting files
PROCESS_TCPDUMP=false
# cosmetic label prepended to output filenames
PROCESS_TCPDUMP_TRAFFIC_TYPE=NFURY_MYSQL
# filter to apply (Be careful, as this could result in a LOT of space)
PROCESS_TCPDUMP_BPF='host 172.16.7.15 and tcp and port 3306'

# WARNING: The trimpcap.py command OVERWRITES the source file so be sure you don't need the original data
#          You'll also need WRITE access to both the original files and the directories containing them
PROCESS_TRIMPCAP=false
# maximum number of bytes per flow to retain
PROCESS_TRIMPCAP_TRIM_LENGTH=30280

PROCESS_ZEEK=false
# Zeek policy to use - be careful with "for572-allfiles"!
PROCESS_ZEEK_POLICY=for572

PROCESS_PASSIVEDNS=false

# This is not needed for the FOR572 capstone evidence!!!
PROCESS_NFCAPD=false

# End processing directives and options - there should be nothing left to change in this script
################################################################################

# Expand and normalize the two paths defined above.  Do not modify the following two lines!
SOURCE_PCAPS=$( eval echo ${SOURCE_PCAPS} )
DEST_DIR_ROOT=$( eval echo ${DEST_DIR_ROOT} )
# End expand/normalize handling

# Get the CPU count
## TODO: Should this include "--ignore 1" to reserve one cpu for other purposes?
NCORES=$( nproc --all )

if [ $UID == 0 ]; then
    echo "WARNING! You're running this script as root (directly or with sudo)."
    echo "         This may not be intended - most evidence processing should be done"
    echo "         with USER-level permissions."
    echo "         Press Ctrl-C to terminate if you don't really NEED to run this as root"
    echo "         or press Return to continue if you truly know what you're doing."
    echo
    echo "   Hint: For all uses in FOR572 courseware, you DO NOT need to run this as root!"
    read
fi

is_legacy_pcap() {
    local filename="$1"
    local filemagic
    filemagic=$( xxd -p -l 4  "${filename}" 2>/dev/null )

    case ${filemagic} in
        d4c3b2a1|a1b2c3d4|4d3cb2a1|a1b23c4d)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

process_pcap_file() {
    local src_file="$1"

    # isolate just the directory path below ${SOURCE_PCAPS}
    local directory=$( dirname ${src_file#${SOURCE_PCAPS}} )
    # isolate just the filename portion
    local filename=$( basename $src_file )

    if ! is_legacy_pcap "${src_file}"; then
        echo "- WARNING: ${src_file} is not a pcap file - skipping"
        continue
    else
        echo "- Processing ${src_file}"
    fi

    if ${PROCESS_TCPDUMP}; then
        local outfile="${DEST_DIR_ROOT}/tcpdump_reduced/${directory}/${PROCESS_TCPDUMP_TRAFFIC_TYPE}_${filename}"

        mkdir -p ${DEST_DIR_ROOT}/tcpdump_reduced/${directory}
        tcpdump -n -s 0 -r "${src_file}" -w "${outfile}" "${PROCESS_TCPDUMP_BPF}" 2> /dev/null

        # remove created file if it's empty
        if [ -f "${outfile}" ] && [ $(stat -c%s "${outfile}" ) -eq 24 ]; then
            rm -f "${outfile}"
        fi
    fi

    if ${PROCESS_TRIMPCAP}; then
        trimpcap.py $TRIM_LENGTH ${src_file}
    fi

    if ${PROCESS_ZEEK}; then
        local origdir=$( pwd )
        local tempdir=$( mktemp -d )

        local pcapmeta=$( capinfos -aeTrxmQ ${src_file} )
        local startts=$( echo ${pcapmeta} | awk -F, '{print $2}' | tr -d '"' )
        local startdate=$( echo ${startts} | awk '{print $1}' )
        local starttime=$( echo ${startts} | awk '{print $2}' | sed -e 's/\..*//' )
        local endts=$( echo ${pcapmeta} | awk -F, '{print $3}' | tr -d '"' )
        local endtime=$( echo ${endts} | awk '{print $2}' | sed -e 's/\..*//' )

        local destdir="${DEST_DIR_ROOT}/zeek_output/${startdate}"
        mkdir -p ${destdir}

        cd ${tempdir}
        zeek ${PROCESS_ZEEK_POLICY} -D -r ${src_file} 2> /dev/null
        # TODO: need to see if this is successful and error out/display message if not

        for zeekfile in *.log; do
            local baselogfile=$( echo ${zeekfile} | sed -e 's/\.log$//' )
            cat ${zeekfile} | gzip -f > ${destdir}/${baselogfile}.${starttime}-${endtime}.log.gz
        done

        cd ${origdir}
        rm -rf ${tempdir}
    fi

    if ${PROCESS_PASSIVEDNS}; then
        mkdir -p ${DEST_DIR_ROOT}/passivedns_output/
        exec 500>>${DEST_DIR_ROOT}/passivedns_output/passivedns.txt
        exec 501>>${DEST_DIR_ROOT}/passivedns_output/passivedns_nxdomain.txt

        # place log events into temp files for later aggregation using file locking
        local temp_pdns_log=$( mktemp )
        local temp_pdns_nxlog=$( mktemp )
        passivedns -q -r ${src_file} -l ${temp_pdns_log} -L ${temp_pdns_nxlog}

        # lock, populate, and unlock the passivedns.txt file
        flock -x 500
        cat ${temp_pdns_log} >> ${DEST_DIR_ROOT}/passivedns_output/passivedns.txt
        flock -u 500

        # lock, populate, and unlock the passivedns_nxdomain.txt file
        flock -x 501
        cat ${temp_pdns_nxlog} >> ${DEST_DIR_ROOT}/passivedns_output/passivedns_nxdomain.txt
        flock -u 501

        # remove temp files
        rm -f ${temp_pdns_log} ${temp_pdns_nxlog}
    fi

    if ${PROCESS_NFCAPD}; then
        mkdir -p ${DEST_DIR_ROOT}/netflow/${filename}
        nfpcapd -r ${src_file} -S 1 -z -l ${DEST_DIR_ROOT}/netflow/${filename}
    fi
}


# create an array of files in the source directory tree
# non-pcap files will be ignored
mapfile -t source_files < <( find -L "${SOURCE_PCAPS}" -type f )
# Iterate across all files in the directory and process as configured in the variables above
if [ ${NCORES} -gt 1 ]; then
    echo "Using ${NCORES} CPUs for parallel processing"
    echo
fi

for source_file in "${source_files[@]}"; do

    process_pcap_file "${source_file}" &

    # Check number of background jobs; wait if > NCORES
    if [ $(jobs -r | wc -l) -ge ${NCORES} ]; then
        wait -n  # Wait for any background job to finish before starting the next
    fi
done

wait
