#!/bin/bash -e

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)
ROOT_DIR=$(dirname "${BASE_DIR}")

# Retrieve arguments
while [[ $# != 0 ]]; do
    case $1 in
        --)
            shift
            break
            ;;
        --machine)
            readonly ARG_MACHINE="$2"
            shift 2
            ;;
        --commits)
            readonly ARG_COMMITS="$2"
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

# Validate the arguments
test -n "${ARG_COMMITS}" || { echo "--commits is not specified" 1>&2; exit 1; }

if [ -z "${ARG_FORCE}" ]; then
    readonly OPT_SKIP_EXISTING='--skip-existing-successful'
fi

# Avoid stdout and stderr streams to be buffered in Python
export PYTHONUNBUFFERED=1

# Configuring machine information
# Note: `asv machine --machine [...] --yes` doesn't collect information
asv machine --yes
if [ -n "${ARG_MACHINE}" ]; then
    asv machine --machine=${ARG_MACHINE} --yes
    readonly OPT_MACHINE=--machine=${ARG_MACHINE}
fi
MACHINE_INFO=$(cat ~/.asv-machine.json | jq ".[\"${ARG_MACHINE}\"]")
test -n "${MACHINE_INFO}" || { echo 'Failed to configure `asv machine`' 1>&2; exit 1; }

# Run benchmark(s) in Docker container
asv run \
    ${OPT_MACHINE} \
    ${OPT_SKIP_EXISTING} \
    --step 1 \
    --parallel $(nproc) \
    --launch-method spawn \
    --show-stderr \
    "${ARG_COMMITS}"
