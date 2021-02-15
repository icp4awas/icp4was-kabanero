#!/bin/bash

# setup environment
. $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

# Allow multiple stacks to be selected
if [ $# -gt 0 ]
then
  export STACKS_LIST="$@"
  echo "STACKS_LIST=$STACKS_LIST"

  for stack_name in $STACKS_LIST
  do
    if [ "${stack_name: -1}" == "/" ]
    then
      stack_name=${stack_name%?}
    fi
     
    stack_no_slash="$stack_no_slash $stack_name"
  done

  STACKS_LIST=$stack_no_slash
fi

if [ -z "$STACKS_LIST" ]
then
  . $script_dir/list.sh
fi

. $script_dir/package.sh
