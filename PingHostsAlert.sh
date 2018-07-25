#! /bin/sh

export LANG=C
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

CMDNAME=$(basename "$0")

COUNT=1
WAIT=5000 # ms

print_usage() {
    echo "Usage: ${CMDNAME} [-?] hostname ..."
    echo "Options:"
    echo "  -?: Show this message."
    exit 0
}

main() {
    if [ $# -eq 0 ]; then
        print_usage
    else
        while getopts \? OPT; do
            case ${OPT} in
                "?")
                    print_usage ;;
            esac
        done
    fi

    for i in "${@}"; do
        ping -c ${COUNT} -W ${WAIT} "${i}"
        if [ $? -ne 0 ]; then
            noti --banner=false --slack \
                 --title "Ping check: ${i} seems DEAD!" \
                 --message "" \
                 echo
        fi
    done

    exit 0
}

main "${@}"
