#!/bin/sh

#  check.sh
#  goagent-osx
#
#  Created by Shengwu Jiang on 9/26/14.
#  Copyright (c) 2014 Shengwu Jiang. All rights reserved.

killProcess() {
    kill -9 `ps aux | grep -E 'python([0-9]+.[0-9]+)? (/.*)+proxy.py$' | grep -v grep | awk '{print $2}'`
}

checkStatus() {
    ps aux | grep -E 'python([0-9]+.[0-9]+)? (/.*)+proxy.py$' | grep -v grep | awk '{print "Pid: "$2"\nPython: "$11"\nScript: "$12}'
}

help() {
    N=$(basename "$0")
    echo "Usage: [sudo] $N \n\t-c : check other proxy.py\n\t-k : kill other proxy.py" >&2
    exit 1
}

case "$1" in
    -c)
        checkStatus
        ;;
    -k)
        killProcess
        ;;
    *)
        help
        ;;
esac

exit 0