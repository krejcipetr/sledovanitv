#!	/bin/bash

source `dirname $0`/sledovanitv-token.sh
export SLEDOVANITVID

$(dirname $0)/sledovanitv-epgconvert.py
exit ${?}
