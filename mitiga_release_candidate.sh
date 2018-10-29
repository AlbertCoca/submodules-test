#!/bin/bash

# Script to perform release candidate


# Create script variables
rc_tag=$1  # Relese tag name as <rcx.y>
rc_last_tag=$2
rc_commit_file="commit_file_$rc_tag.txt"  # File containing the changes of the release candidate

if [[ $rc_tag =~ rc[0-9]{1,3}\.[0-9]{1,3} ]]; then
    echo "Execution release candidate script for tag $rc_tag"
else
    echo "Tag should follow the regex: rc[0-9]{1,3}\\.[0-9]{1,3}"
    exit 1
fi
if [[ $rc_last_tag =~ rc[0-9]{1,3}\.[0-9]{1,3} ]]; then
    echo "Execution release candidate script for tag $rc_last_tag"
else
    echo "Tag should follow the regex: rc[0-9]{1,3}\\.[0-9]{1,3}"
    exit 1
fi

###########################
# For all subrepositories #
###########################

# Integrate all previous release hotfixes to develop branch
echo "Checkout Develop"
git submodule foreach git checkout develop
echo "Pull all"
git submodule foreach --recursive git pull origin develop
# git submodule foreach git merge rcandidate --no-commit
# git submodule foreach git commit -m "Merge rcandidate $rc_tag into develop" --allow-empty

# Tag it as new release candidate
echo "Add tag $rc_tag for each submodule at develop"
git submodule foreach git tag $rc_tag
git submodule foreach git push origin --tags

# Change to release candidate branch and merge develop new features to it
# Use squash option to generate a unique new commit and use as commit message
# a file that is a compedium of the new features/fixes onliners logs.
echo "Checkout rcandidate"
git submodule foreach git checkout rcandidate
echo "Merge develop into rcandidate"
git submodule foreach git merge develop --no-ff --no-commit
echo "Commit with message from file"
git submodule foreach "echo 'RELEASE CANDIDATE $rc_tag\n' > $rc_commit_file && git log --oneline $rc_last_tag..$rc_tag >> $rc_commit_file && git commit --all --file=$rc_commit_file --allow-empty"

# Tag this new rcandidate version with a 0 (clean candidate at the time being)
# Push all changes (new tags and commits) discarting release commit file
echo "Add tag $rc_tag.0 for each submodule at rcandidate"
git submodule foreach git tag $rc_tag.0
echo "Push tags"
git submodule foreach git push origin --tags
echo "Push all"
git submodule foreach git push --all
echo "Delete temporaly files"
git submodule foreach rm $rc_commit_file


#########################
# For Mitiga repository #
#########################

# Integrate previous version hotfixes to develop
echo "Checkout develop"
git checkout develop
echo "merge rcandidate to develop"
git merge rcandidate --no-commit 

# Create new commit file using subrepos changes for the new version.
echo "Create a new file for commit message"
echo -e "RELEASE CANDIDATE $rc_tag\n" > history/$rc_commit_file && git submodule foreach "echo '_____________________________________________________' && git log --oneline $rc_last_tag..$rc_tag && echo '\n'" >> history/$rc_commit_file
# echo -e "RELEASE CANDIDATE $rc_tag\n" > history/$rc_commit_file && git submodule foreach \"git log --oneline $rc_last_tag..$rc_tag && echo '----------------------------------------------------------------------------------------'\" >> history/$rc_commit_file

# Commit new release version including new release commit file (and tag it)
echo "Add commit file $rc_commit_file"
git add history/$rc_commit_file
echo "Add all"
git add -A
echo "Commit with message $rc_commit_file"
git commit --file=history/$rc_commit_file --allow-empty
echo "Create tag $rc_tag"
git tag $rc_tag

# Go to rcandidate, rebase develop changes and tag it as .0 (clean candidate)
echo "Checkout rcandidate"
git checkout rcandidate 
echo "Rebase develop rcandidate"
git rebase develop rcandidate
echo "Add tag $rc_tag.0 at rcandidate"
git tag $rc_tag.0

# Push it all!!
echo "Push tags"
git push --tags
echo "Push all"
git push --all
echo "Release candidate $rc_tag done!! :D"

