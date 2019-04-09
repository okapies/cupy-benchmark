#!/bin/bash -e

IMAGE_ID='okapies/cupy-benchmark:cuda9.2-cudnn7'

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)
ROOT_DIR=$(dirname "${BASE_DIR}")

# Collect environment information in which run the benchmark
source ${BASE_DIR}/collect_env.sh

echo "Running cupy-benchmark for all releases..."

# Download the past results (if needed)

# Run the benchmark in Docker container
docker run \
    --rm \
    --runtime=nvidia \
    -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -u $(id -u $USER):$(id -g $USER) \
    -v ${ROOT_DIR}:/work --workdir=/work \
    -e MACHINE_ID=${MACHINE_ID} \
    "${IMAGE_ID}" \
    bash -ex .pfnci/run_benchmark.sh --machine "${MACHINE_ID}" --branches master

# Upload the results

# Visualize the results and upload to website
