#!	/bin/bash

source `dirname $0`/sledovanitv-token.sh

wget -q -O- "http://sledovanitv.cz/api/epg?PHPSESSID=${PHPSESSID}&detail=1&duration=1439" | $(dirname $0)/sledovanitv-epgconvert.py
