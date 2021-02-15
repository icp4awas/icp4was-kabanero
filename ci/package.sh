#!/bin/bash -x

# setup environment
. $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

# remember images to push
> $build_dir/image_list

# expose an extension point for running before main 'package' processing
exec_hooks $script_dir/ext/pre_package.d

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
        index_file_path=$assets_dir/$index_name

        echo -e "\n- LINTING stack: $stack_id"
        if appsody stack lint 
        then
            echo "appsody stack lint: ok"
        else
            echo "Error linting $stack_id"
            exit 1
        fi

        rm -f ${build_dir}/*.$stack_id.$stack_version.log

        echo -e "\n- PACKAGING stack: $stack_id, log: ${build_dir}/package.$stack_id.$stack_version.log"
        echo "PACKAGING stack: $stack_id" > ${build_dir}/package.$stack_id.$stack_version.log
        if logged ${build_dir}/package.$stack_id.$stack_version.log \
            appsody stack package \
            --image-registry $IMAGE_REGISTRY \
            --image-namespace $IMAGE_REGISTRY_ORG
        then
            echo "appsody stack package: ok, $IMAGE_REGISTRY_ORG/$stack_id:$stack_version"
            trace "${build_dir}/package.$stack_id.$stack_version.log"

            if [ "$SKIP_TESTS" != "true" ]
            then
                echo -e "\n- VALIDATING stack: $stack_id, log: ${build_dir}/validate.$stack_id.$stack_version.log"
                echo "VALIDATING stack: $stack_id" > ${build_dir}/validate.$stack_id.$stack_version.log
                if logged ${build_dir}/validate.$stack_id.$stack_version.log \
                    appsody stack validate \
                    --no-lint --no-package \
                    --image-registry $IMAGE_REGISTRY \
                    --image-namespace $IMAGE_REGISTRY_ORG
                then
                    echo "appsody stack validate: ok"
                    trace "${build_dir}/validate.$stack_id.$stack_version.log"
                else
                    stderr "${build_dir}/validate.$stack_id.$stack_version.log" 
                    stderr "appsody stack validate: error"
                    exit 1
                fi
            fi
        else
            stderr "${build_dir}/package.$stack_id.$stack_version.log"
            stderr "appsody stack package: error" 
            exit 1
        fi

        echo "$IMAGE_REGISTRY/$IMAGE_REGISTRY_ORG/$stack_id" >> $build_dir/image_list
        echo "$IMAGE_REGISTRY/$IMAGE_REGISTRY_ORG/$stack_id:$stack_version" >> $build_dir/image_list
        echo "$IMAGE_REGISTRY/$IMAGE_REGISTRY_ORG/$stack_id:$stack_version_major" >> $build_dir/image_list
        echo "$IMAGE_REGISTRY/$IMAGE_REGISTRY_ORG/$stack_id:$stack_version_major.$stack_version_minor" >> $build_dir/image_list

        echo -e "\n- ADD $stack_id with release URL prefix $RELEASE_URL/$stack_id-v$stack_version/"
        if appsody stack add-to-repo $stack_id \
            --release-url $RELEASE_URL/$stack_id-v$stack_version/ \
            $useCachedIndex
        then
            useCachedIndex="--use-local-cache"
        else
            echo "Error running 'appsody stack add-to-repo' command"
            exit 1
        fi

        for template_dir in $stack_dir/templates/*/
        do
            if [ -d $template_dir ]
            then
                template_id=$(basename $template_dir)
                versioned_archive=$stack_id.v$stack_version.templates.$template_id.tar.gz
                packaged_archive=$stack_id.v$stack_version.templates.$template_id.tar.gz
                if [ -f $HOME/.appsody/stacks/dev.local/$packaged_archive ]; then
                    echo "--- Copying $HOME/.appsody/stacks/dev.local/$packaged_archive to $assets_dir/$versioned_archive"
                    cp $HOME/.appsody/stacks/dev.local/$packaged_archive $assets_dir/$versioned_archive
                fi
            fi
        done
        source_archive=$stack_id.v$stack_version.source.tar.gz
        packaged_source_archive=$stack_id.v$stack_version.source.tar.gz
        if [ -f $HOME/.appsody/stacks/dev.local/$packaged_source_archive ]; then
            echo "--- Copying $HOME/.appsody/stacks/dev.local/$packaged_source_archive to $assets_dir/$source_archive"
            cp $HOME/.appsody/stacks/dev.local/$packaged_source_archive $assets_dir/$source_archive
        fi

        if [ "$useCachedIndex" != "" ]; then
            if [ -f $HOME/.appsody/stacks/dev.local/$stack_id-index.yaml ]; then
                cp $HOME/.appsody/stacks/dev.local/$stack_id-index.yaml $assets_dir/$index_name.yaml
            fi
            if [ -f $HOME/.appsody/stacks/dev.local/$stack_id-index.json ]; then
                cp $HOME/.appsody/stacks/dev.local/$stack_id-index.json $assets_dir/$index_name.json
            fi
        else
            url="$RELEASE_URL/../latest/download/$index_name.yaml"
            curl -s -L ${url} -o $assets_dir/$index_name.yaml
            url="$RELEASE_URL/../latest/download/$index_name.json"
            curl -s -L ${url} -o $assets_dir/$index_name.json
        fi

        popd
    fi
done


# expose an extension point for running after main 'package' processing
exec_hooks $script_dir/ext/post_package.d

if [ "$CODEWIND_INDEX" == "true" ]; then
    python3 $script_dir/create_codewind_index.py -n $DISPLAY_NAME_PREFIX -f $assets_dir
    
    # iterate over each repo
    for codewind_file in $assets_dir/*.json
    do
        # flat json used by static appsody-index for codewind
        index_src=$build_dir/index-src/$(basename "$codewind_file")

        sed -e "s|${RELEASE_URL}/.*/|{{EXTERNAL_URL}}/|" $codewind_file > $index_src
    done
fi

