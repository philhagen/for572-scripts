alias NetworkMiner="mono /usr/local/for572/NetworkMiner/NetworkMiner.exe"
alias squidtime="awk '{\$1=strftime(\"%F %T\", \$1, 1); print \$0}'"
alias workbook-update="/bin/bash /var/www/html/workbook/resources/workbook-update.sh"
alias wsreset="cp -a enabled_protos.DIST enabled_protos ; cp -a maxmind_db_paths.DIST maxmind_db_paths ; cp -a preferences.DIST  preferences ; cp -a recent.DIST recent ; cp -a recent_common.DIST recent_common"
