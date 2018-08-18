#! /bin/sh

export LANG=C
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

BASEDIR=$(cd "$(dirname "$0")" && pwd)
CONFDIR=${BASEDIR}
CMDNAME=$(basename "$0")

COUNT=1
WAIT=5000 # ms

# shellcheck source=./pinghostsalert.conf
. ${CONFDIR}/pinghostsalert.conf
export NOTI_SLACK_CHANNEL
export NOTI_SLACK_TOKEN

DOWNLIST=${BASEDIR}/down.lst

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

    touch -a ${DOWNLIST}
    tmplist=$(mktemp ${BASEDIR}/${CMDNAME}.XXXXXX) || exit 1
    cat ${DOWNLIST} > ${tmplist}

    alives=""

    for i in "${@}"; do
        ping -c ${COUNT} -W ${WAIT} "${i}"
        if [ $? -ne 0 ]; then
            if ! [ $(grep ${i} ${tmplist}) ]; then
                noti --banner=false --slack \
                     --title "Ping check: ${i} seems DEAD!" \
                     --message "" \
                     echo
                echo ${i} >> ${tmplist}
            fi
        else
            if [ -z "${alives}" ]; then
                alives="(${i}"
            else
                alives="${alives}|${i}"
            fi
        fi
    done
    if [ -n "${alives}" ]; then
        alives="${alives})"
    fi

    if [ -n "${alives}" ]; then
        sort ${tmplist} | uniq | grep -v -E "${alives}" > ${DOWNLIST}
    fi
    rm -f ${tmplist}

    exit 0
}

main "${@}"
