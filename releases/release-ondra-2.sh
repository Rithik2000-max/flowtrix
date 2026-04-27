#/bin/bash

# Release script for wekan-ondra and wekan-gantt-gpl
# part 2. Before these, part 1 and merge and fix merge conflicts.

# 1) Check that there is only one parameter
#    of wekan version number:

if [ $# -ne 1 ]
  then
    echo "Syntax with wekan version number:"
    echo "  ./release-ondra-2.sh 5.10"
    exit 1
fi

# 2) Move wekan version tag to be newest after merge
#    and push to repo.
git add --all
git commit -m "Merge newest changes."
git tag --force v$1 HEAD
git push --tags --force
git push --follow-tags
