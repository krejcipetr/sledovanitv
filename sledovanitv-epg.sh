#!	/bin/bash

source `dirname $0`/sledovanitv-token.sh

$(dirname $0)/sledovanitv-epgconvert.py
