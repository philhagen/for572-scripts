#!/bin/bash
# (C)2019 Lewes Technology Consulting, LLC

# This script will traverse a directory tree full of 7zip archive files and
#   run an extraction command against each.
# As distributed, it's designed to handle the capstone data in FOR572, but you
#   can adjust it as needed for other situations.

# Set thsese three variables as needed.  Be mindful of the space available in
#   $TARGETDIR, as the commands below may require a LOT of disk space!
SOURCEDIR=/path/to/directory/with/7zip_files/
TARGETDIR=/some/other/destination/path
PASSWORD='password' # keep the single quotes to prevent shell expansion!!

for arch in $( find ${SOURCEDIR} -type f -name \*.7z ); do
    echo
    echo "- processing ${arch}";

    directory=$( dirname ${arch#${SOURCEDIR}} )
    mkdir -p ${TARGETDIR}/${directory}
    7z x -o${TARGETDIR}/${directory} -p${PASSWORD} ${arch}
done