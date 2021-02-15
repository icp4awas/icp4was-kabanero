#!/bin/bash

# setup environment
. $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

# directory to store assets for test or release
assets_dir=$base_dir/ci/assets

echo "Assets in /ci/assets are:"
echo "-------------------------------"
ls -al $assets_dir
echo "-------------------------------"

for index in $(ls $assets_dir/*.yaml 2>/dev/null | sort)
do
	echo "Content of index file $(basename $index) is:"
	echo "-------------------------------"
	cat $index
	echo "-------------------------------"
done
