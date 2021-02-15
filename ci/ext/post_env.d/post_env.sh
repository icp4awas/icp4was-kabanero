#!/bin/bash
set -e

if [ -z $RELEASE_NAME ]; then 
    if [ -z $TRAVIS_TAG ]; then
        if [ -f $base_dir/VERSION ]; then
            export RELEASE_NAME="$(cat $base_dir/VERSION)"
        fi
    else
        export RELEASE_NAME=$TRAVIS_TAG
    fi
fi

export COPYFILE_DISABLE=1

mkdir -p $HOME/.appsody/stacks/dev.local