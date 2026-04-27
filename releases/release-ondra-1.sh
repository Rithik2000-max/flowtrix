#!/bin/bash

# Release script for wekan-ondra and wekan-gantt-gpl
# part 1. After this merge and fix merge conflicts, and part 2.

# 1) Check that there is only one parameter
#    of wekan version number:

if [ $# -ne 1 ]
  then
    echo "Syntax with wekan version number:"
    echo "  ./release-ondra-2.sh 5.10"
    exit 1
fi

# 2) Get up
git fetch upstream
git merge upstream/master
