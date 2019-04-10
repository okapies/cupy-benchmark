#!/bin/bash -e

IMAGE_ID='okapies/cupy-benchmark:cuda9.2-cudnn7'

RESULT_BUCKET_NAME=chainer-pfn-private-ci
WEBSITE_BUCKET_NAME=
PROJECT_NAME=cupy-benchmark
RESULTS_DIR=results
HTML_DIR=html

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)
ROOT_DIR=$(dirname "${BASE_DIR}")

readonly GS_SRC_DIR=gs://${RESULT_BUCKET_NAME}/${PROJECT_NAME}/${RESULTS_DIR}
readonly DEST_DIR=${ROOT_DIR}

# Load helper functions
source ${BASE_DIR}/gcp_helper.sh

# Download the benchmark results
${GSUTIL_CMD} cp -r ${GS_SRC_DIR} ${DEST_DIR}

# Run the benchmark in Docker container
docker run \
    --rm \
    -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro \
    -u $(id -u $USER):$(id -g $USER) \
    -v ${ROOT_DIR}:/work --workdir=/work \
    "${IMAGE_ID}" \
    asv publish --html-dir ./${HTML_DIR}

# TODO: publish the website to the public bucket
