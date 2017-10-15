#!/bin/bash
for i in 01; do
    echo "Creating working directory for Demo ${i}"
    mkdir /cases/for572/demo-${i}
    if [ -f /mnt/hgfs/lab_data/Demo-${i}_source_evidence.zip ]; then
        echo " - Extracting source evidence for Demo ${i}"
        unzip -q -d /cases/for572/demo-${i} /mnt/hgfs/lab_data/Demo-${i}_source_evidence.zip
    fi
    echo
done

for i in $( seq -w 1 14); do
    echo "Creating working directory for Lab ${i}"
    mkdir /cases/for572/lab-${i}
    if [ -f /mnt/hgfs/lab_data/Lab-${i}_source_evidence.zip ]; then
        echo " - Extracting source evidence for Lab ${i}"
        unzip -q -d /cases/for572/lab-${i} /mnt/hgfs/lab_data/Lab-${i}_source_evidence.zip
    fi
    echo
done
