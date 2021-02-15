#!/bin/bash
set -e

# setup environment
. $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../env.sh

# directory to store assets for test or release
assets_dir=$base_dir/ci/assets
mkdir -p $assets_dir
mkdir -p $base_dir/ci/build/index-src

# url for downloading released assets
release_url="https://github.com/$TRAVIS_REPO_SLUG/releases/download"

# iterate over each stack
for stack in $(ls $base_dir/*/stack.yaml 2>/dev/null | sort)
do
    echo $stack
    stack_dir=$(dirname $stack)

    if [ -d $stack_dir ]
    then
        pushd $stack_dir

        stack_id=$(basename $stack_dir)
        stack_version=$(awk '/^version *:/ { gsub("version:","",$NF); gsub("\"","",$NF); print $NF}' $stack)
        stack_version_major=`echo $stack_version | cut -d. -f1`
        stack_version_minor=`echo $stack_version | cut -d. -f2`
        stack_version_patch=`echo $stack_version | cut -d. -f3`

        index_name=$stack_id-$stack_version-index

        index_file_v2=$assets_dir/$index_name.yaml
        index_file_local_v2=$assets_dir/$index_name-local.yaml
        index_file_v2_temp=$assets_dir/$index_name-temp.yaml
        nginx_file=$base_dir/ci/build/index-src/$index_name.yaml
        
        if [ -f $index_file_v2 ]; then
            # Copy index file as we will update later
            cp $index_file_v2 $index_file_v2_temp
            
            # Resolve external URL for local / github release
            sed -e "s|${RELEASE_URL}/.*/|file://$assets_dir/|" $index_file_v2_temp > $index_file_local_v2
            if [ "${BUILD_RELEASE}" == "true" ]; then
	            if [ ! -z $RELEASE_NAME ]; then
    	            sed -e "s|${RELEASE_URL}/.*/|${RELEASE_URL}/${RELEASE_NAME}/|" $index_file_v2_temp > $index_file_v2
    	        fi
            fi
            rm -f $base_dir/ci/build/index-src/*.yaml
            sed -e "s|${RELEASE_URL}/.*/|{{EXTERNAL_URL}}/|" $index_file_v2_temp > $nginx_file
            rm -f $index_file_v2_temp
        fi
        
        popd

    else
        echo "SKIPPING: $repo_dir"
    fi
done
