#!/bin/bash

# setup environment
. $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

# expose an extension point for running beforer main 'list' processing
exec_hooks $script_dir/ext/pre_list.d

if [ -z "$STACKS_LIST" ]
then
    echo "Listing all stacks"
    for stack_exists in $base_dir/*/stack.yaml
    do
        if [ -f $stack_exists ]
        then
            var=`echo ${stack_exists#"$base_dir/"}`
            repo_stack=`awk '{split($1, a, "/*"); print a[1]}' <<< $var`
            STACKS_LIST+=("$repo_stack")
        fi
    done
    STACKS_LIST=${STACKS_LIST[@]}
fi

echo "Building stacks: $STACKS_LIST"

# expose environment variable for stacks
export STACKS_LIST

# expose an extension point for running after main 'list' processing
exec_hooks $script_dir/ext/post_list.d
