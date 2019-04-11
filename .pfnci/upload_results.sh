#!/bin/bash -e

DEFAULT_PROJECT=cupy-benchmark
RESULTS_DIR=results
MACHINE_JSON=machine.json

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)
ROOT_DIR=$(dirname "${BASE_DIR}")

# Retrieve arguments
while [[ $# != 0 ]]; do
    case $1 in
        --)
            shift
            break
            ;;
        --bucket)
            readonly ARG_BUCKET="$2"
            shift 2
            ;;
        --project)
            readonly ARG_PROJECT="$2"
            shift 2
            ;;
        --machine)
            readonly ARG_MACHINE="$2"
            shift 2
            ;;
        -*)
            echo Unknown option \"$1\" 1>&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Validate the arguments
test -n "${ARG_BUCKET}" || { echo "--bucket is not specified" 1>&2; exit 1; }
test -n "${ARG_MACHINE}" || { echo "--machine is not specified" 1>&2; exit 1; }

# Options that have default value
test -n "${ARG_PROJECT}" || readonly ARG_PROJECT=${DEFAULT_PROJECT}

readonly SRC_DIR=${ROOT_DIR}/${RESULTS_DIR}
readonly GS_DEST_DIR=gs://${ARG_BUCKET}/${ARG_PROJECT}/${RESULTS_DIR}

# Prepare temporary file(s)
readonly SRC_MACHINE_JSON=$(mktemp --suffix='-machine.json')
readonly DEST_MACHINE_JSON=$(mktemp --suffix='-machine.json')
trap 'rm -f "${SRC_MACHINE_JSON}" "${DEST_MACHINE_JSON}"' 1 2 3 15 EXIT

# Load helper functions
source ${BASE_DIR}/utils.sh
source ${BASE_DIR}/gcp_utils.sh

# Check if machine.json is stable
cat ${SRC_DIR}/${ARG_MACHINE}/${MACHINE_JSON} | jq -S . > ${SRC_MACHINE_JSON}
gs_cat ${GS_DEST_DIR}/${ARG_MACHINE}/${MACHINE_JSON} | jq -S . > ${DEST_MACHINE_JSON} || true

if [ -s "${DEST_MACHINE_JSON}" ]; then
    readonly DIFF_MACHINE_JSON=$(diff -u ${SRC_MACHINE_JSON} ${DEST_MACHINE_JSON} || true)
fi
if [ -n "${DIFF_MACHINE_JSON}" ]; then
    echo "Warning: the machine specification is not stable:" 1>&2
    echo "${DIFF_MACHINE_JSON}" 1>&2
fi

# Upload all .json in RESULTS_DIR/ARG_MACHINE (including machine.json)
${GSUTIL_CMD} cp -z json ${SRC_DIR}/benchmarks.json ${GS_DEST_DIR}/benchmarks.json
${GSUTIL_CMD} \
    -o "GSUtil:parallel_process_count="$(nproc) \
    -o "GSUtil:parallel_thread_count=1" \
    -m \
    cp \
    -z json \
    ${SRC_DIR}/${ARG_MACHINE}/*.json ${GS_DEST_DIR}/${ARG_MACHINE}
