#!/bin/bash -e

# This is a workaround to use jq command; replace to the actual command in the future
if ! command -v jq >/dev/null 2>&1; then
    echo 'Setting up jq via Docker...' 1>&2
    # define a function mimicking the actual command
    function jq() {
        docker run -i --rm okapies/jq:1.5 "$@"
    }
    if ! jq --version; then
        echo "Run as sudo or install jq to your environment." 1>&2
    fi
fi
