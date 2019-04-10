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
        --branches)
            readonly ARG_BRANCHES="$2"
            shift 2
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

# Validate the arguments
test -n "${ARG_BRANCHES}" || { echo "--branches is not specified" 1>&2; exit 1; }

# Configuring machine information
# Note: `asv machine --machine [...] --yes` doesn't collect information
asv machine --yes
if [ -n "${ARG_MACHINE}" ]; then
    asv machine --machine=${ARG_MACHINE}
fi

MACHINE_INFO=$(cat ~/.asv-machine.json | jq ".[\"${ARG_MACHINE}\"]")
test -n "${MACHINE_INFO}" || { echo 'Failed to configure `asv machine`' 1>&2; exit 1; }

# Run benchmark(s) in Docker container
asv run \
    --machine "${ARG_MACHINE}" \
    --step 1 \
    --parallel $(nproc) \
    --launch-method spawn \
    --show-stderr \
    "${ARG_BRANCHES}"
