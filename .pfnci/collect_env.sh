#!/bin/bash -e

function slugify() {
    cat - | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr 'A-Z' 'a-z'
}

# Assumes that the machine equips only one type of CPU (and GPU) 
readonly CPU_MODEL_NAME=$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*).*/\1/p' | head -n1 | sed -e 's/(R)//g')
readonly CPU_CORES=$(nproc)

readonly MEM_SIZE=$(cat /proc/meminfo | sed -nr '/MemTotal/ s/.*:\s*(.*).*/\1/p' | awk '{ printf "%d", $1/1024/1024 ; exit}' | head -n1)

if command -v nvidia-smi >/dev/null 2>&1; then
    readonly GPU_MODEL_NAME=$(nvidia-smi --query-gpu=gpu_name,memory.total --format=csv,noheader | head -n1 | awk -F', ' '{print $1 " " $2}')
fi

# e.g. Intel Xeon CPU E5-2630 v3 @ 2.40GHz (8 cores) + 62GB + Quadro K420 979 MiB
MACHINE_DESC="${CPU_MODEL_NAME} (${CPU_CORES} cores) + ${MEM_SIZE}GB"
if [ -n "${GPU_MODEL_NAME}" ]; then
    MACHINE_DESC=${MACHINE_DESC}' + '${GPU_MODEL_NAME}
fi

# e.g. intel-xeon-cpu-e5-2630-v3-2-40ghz-8-cores-62gb-quadro-k420-979-mib
readonly MACHINE_ID=$(echo "${MACHINE_DESC}" | slugify)
