#!/bin/bash -e

IMAGE_ID='okapies/cupy-benchmark:cuda9.2-cudnn7'

PROJECT_NAME=cupy-benchmark
BUCKET_NAME=chainer-pfn-private-ci
REPO_URL=https://github.com/cupy/cupy.git
REPO_DIR=cupy

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)
ROOT_DIR=$(dirname "${BASE_DIR}")

# Retrieve arguments
while [[ $# != 0 ]]; do
    case $1 in
        --)
            shift
            break
            ;;
        --pattern)
            readonly ARG_PATTERN="$2"
            shift 2
            ;;
        --force)
            readonly ARG_FORCE='true'
            shift 1
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

# Collect environment information in which run the benchmark
source ${BASE_DIR}/collect_env.sh

echo "Running cupy-benchmark for all releases..."

# Download the past results (if needed)
if [ -n "${ARG_PATTERN}" ]; then
    readonly OPT_PATTERN=${ARG_PATTERN}
fi
if [ -n "${ARG_FORCE}" ]; then
    readonly OPT_FORCE='--force'
fi

# Clone the repository before running asv and retrieve a list of tags
docker run \
    --rm \
    -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -u $(id -u $USER):$(id -g $USER) \
    -v ${ROOT_DIR}:/work --workdir=/work \
    "${IMAGE_ID}" \
    bash -exc "git clone ${REPO_URL} ${REPO_DIR}"
REPO_TAGS=$(docker run \
    --rm \
    -v ${ROOT_DIR}:/work --workdir=/work/${REPO_DIR} \
    ${IMAGE_ID} \
    git tag -l "${OPT_PATTERN}")

# Run the benchmark in Docker container
for tag in ${REPO_TAGS}; do
    docker run \
        --rm \
        --runtime=nvidia \
        -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -u $(id -u $USER):$(id -g $USER) \
        -v ${ROOT_DIR}:/work --workdir=/work \
        "${IMAGE_ID}" \
        bash -ex .pfnci/run_benchmark.sh \
            ${OPT_FORCE} \
            --machine "${MACHINE_ID}" \
            --commits ${tag} \
        || true  # considered to be successful even if the benchmark fails

    # Upload the result
    bash -e ${BASE_DIR}/upload_results.sh \
        --bucket "${BUCKET_NAME}" \
        --project "${PROJECT_NAME}" \
        --machine "${MACHINE_ID}"
done
