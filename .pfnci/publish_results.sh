#!/bin/bash -e

IMAGE_ID='cupy/cupy-benchmark:cuda9.2-cudnn7'

RESULT_BUCKET_NAME=chainer-pfn-private-ci
WEBSITE_BUCKET_NAME=chainer-artifacts-pfn-public-ci
PROJECT_NAME=cupy-benchmark
RESULTS_DIR=results
HTML_DIR=html

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)
ROOT_DIR=$(dirname "${BASE_DIR}")

readonly GS_SRC_DIR=gs://${RESULT_BUCKET_NAME}/${PROJECT_NAME}/${RESULTS_DIR}
readonly DEST_DIR=${ROOT_DIR}

readonly HTML_SRC_DIR=${ROOT_DIR}/${HTML_DIR}
readonly GS_HTML_DEST_DIR=gs://${WEBSITE_BUCKET_NAME}/${PROJECT_NAME}

# Load helper functions
source ${BASE_DIR}/gcp_utils.sh

# Download the benchmark results
${GSUTIL_CMD} -m cp -r ${GS_SRC_DIR} ${DEST_DIR}

# Run the benchmark in Docker container
docker run \
    --rm \
    -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro \
    -u $(id -u $USER):$(id -g $USER) \
    -v ${ROOT_DIR}:/work --workdir=/work \
    -e PYTHONUNBUFFERED=1 \
    "${IMAGE_ID}" \
    asv publish --html-dir ./${HTML_DIR}

# Publish the website to the public bucket
# TODO: enable gzip compression
${GSUTIL_CMD} -m rsync -r ${HTML_SRC_DIR} ${GS_HTML_DEST_DIR}

echo "Uploaded to https://storage.googleapis.com/${WEBSITE_BUCKET_NAME}/${PROJECT_NAME}/index.html"
