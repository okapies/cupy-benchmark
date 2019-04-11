#!/bin/bash -e

IMAGE_ID='okapies/cupy-benchmark:cuda9.2-cudnn7'

PROJECT_NAME=cupy-benchmark
BUCKET_NAME=chainer-pfn-private-ci

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)
ROOT_DIR=$(dirname "${BASE_DIR}")

# Retrieve arguments
while [[ $# != 0 ]]; do
    case $1 in
        --)
            shift
            break
            ;;
        --force)
            readonly ARG_FORCE='true'
            shift 1
            ;;
        -*)
            echo Unknown option \"$1\" 1>&2
            exit
            ;;
        *)
            break
            ;;
    esac
done

# Collect environment information in which run the benchmark
source ${BASE_DIR}/collect_env.sh

echo "Running cupy-benchmark for all releases..."

# Download the past results (if needed)
if [ -n "${ARG_FORCE}" ]; then
    readonly OPT_FORCE='--force'
fi

# Run the benchmark in Docker container
docker run \
    --rm \
    --runtime=nvidia \
    -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -u $(id -u $USER):$(id -g $USER) \
    -v ${ROOT_DIR}:/work --workdir=/work \
    "${IMAGE_ID}" \
    bash -ex .pfnci/run_benchmark.sh \
        ${OPT_FORCE} \
        --machine "${MACHINE_ID}" \
        --commits master \
    || true  # considered to be successful even if the benchmark fails

# Upload the results
bash -e ${BASE_DIR}/upload_results.sh \
    --bucket "${BUCKET_NAME}" \
    --project "${PROJECT_NAME}" \
    --machine "${MACHINE_ID}"
