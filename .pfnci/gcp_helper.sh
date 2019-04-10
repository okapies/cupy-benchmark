#!/bin/bash -e

GSUTIL_CMD=gsutil

function gs_cat() {
    local target=$1

    local stat  # it must be declared independently to get the exit code
    stat=$(${GSUTIL_CMD} stat ${target})
    ret=$?

    if [ ${ret} -eq 0 ]; then
        local encoding=$(echo "${stat}" | sed -nr '/Content-Encoding/ s/.*:\s*(.*).*/\1/p')
        if [ "${encoding}" == "gzip" ]; then
            ${GSUTIL_CMD} cat ${target} | gunzip -c
        else
            ${GSUTIL_CMD} cat ${target}
        fi
    else
        echo 1>&2
        return ${ret}
    fi
}
