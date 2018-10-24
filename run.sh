#!/usr/bin/env bash
set -eE +o posix -o pipefail

source /tools/Bio-tools/miniconda3/bin/activate snakemake

declare output=$(echo $CONFIG_JSON | jq '(.output)?//""' -r)
declare process=$(echo $CONFIG_JSON | jq '(.process)?//""' -r)

set -x 

exec snakemake all \
	--jobs $process \
	--forceall \
	--timestamp \
	--latency-wait 120 \
	--directory "$output"
