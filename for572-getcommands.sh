#!/bin/bash

TARGET_DIR=~/for572-commands/

if [ -d ${TARGET_DIR} ]; then
    echo "Looks like you've already run this... seeing if there are any updates"
    echo
    cd ${TARGET_DIR}
    git pull 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "ERROR: Something went wrong - you should manually remove the"
        echo "  ${TARGET_DIR} directory and try again."
        exit 1
    fi

else
    echo "This script will retrieve a list of all commands in the FOR572 Exercise"
    echo "  Workbook.  You must supply the version number of your course materials"
    echo "  below.  To find this, look in the front cover of the workbook - you will"
    echo "  see something such as the following:"
    echo "  For572_Wkbk_D03_01"
    echo "              ^^^"
    echo
    echo "  For the above version, enter the 'D03'.  If you enter an incorrect"
    echo "  version string, this command will fail, your commands will be"
    echo "  inconsistent with the course books, or both."
    echo
    echo -n "Enter the version string: "
    read COURSE_VERSION

    # convert response to uppercase and validate against regex
    COURSE_VERSION=$( echo $COURSE_VERSION | tr '[:lower:]' '[:upper:]' )
    if ! [[ ${COURSE_VERSION} =~ ^[A-Z][0-9][0-9]$ ]]; then
        echo "ERROR: Courseware version string is not correct. Exiting."
        exit 2;
    fi

    echo "Attempting to retrieve version ${COURSE_VERSION}"

    git clone -b ${COURSE_VERSION} for572.com:commandlines ${TARGET_DIR} 2> /dev/null

    echo
    echo "You should now have a series of text files in the ${TARGET_DIR} directory."
fi
