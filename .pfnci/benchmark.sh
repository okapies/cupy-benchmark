#!/bin/bash -e

IMAGE_ID='okapies/cupy-benchmark:cuda9.2-cudnn7'

PROJECT_NAME=cupy-benchmark
BUCKET_NAME=chainer-pfn-private-ci

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)
ROOT_DIR=$(dirname "${BASE_DIR}")

# Collect environment information in which run the benchmark
source ${BASE_DIR}/collect_env.sh

echo "Running cupy-benchmark for the latest commit..."

# Download the past results (if needed)

# Run the benchmark in Docker container
docker run \
    --rm \
    --runtime=nvidia \
    -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro \
    -u $(id -u $USER):$(id -g $USER) \
    -v ${ROOT_DIR}:/work --workdir=/work \
    "${IMAGE_ID}" \
    bash -ex .pfnci/run_benchmark.sh \
        --machine "${MACHINE_ID}" \
        --branches master \
    || true  # considered to be successful even if the benchmark fails

# Upload the results
# Note: using Docker is just for jq
docker run \
    --rm \
    -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro \
    -u $(id -u $USER):$(id -g $USER) \
    -v ${ROOT_DIR}:/work --workdir=/work \
    "${IMAGE_ID}" \
    bash -e .pfnci/upload_results.sh \
        --bucket "${BUCKET_NAME}" \
        --project "${PROJECT_NAME}" \
        --machine "${MACHINE_ID}"

# TODO: send a notification when `asv compare` detects performance degradation
