#!/bin/bash



hotfix_tag=$1

if [[ $hotfix_tag =~ rc[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; then
    echo "Execution release candidate script for tag $rc_tag"
else
    echo "Tag should follow the regex: rc[0-9]{1,3}\\.[0-9]{1,3}"
    exit 1
fi

run_dir=$PWD
hotfix_file="hotfix_$hotfix_tag.txt"

shift

for repo in "$@"
do
    cd $run_dir/$repo
    hotfix_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $hotfix_branch != *"hotfix"* ]]; then
        echo "The subrepo: $repo/$hotfix_branch does not seems to be a hotfix branch"
        exit
    fi
done

for repo in "$@"
do
    echo $repo
    
    cd $run_dir/$repo
    hotfix_branch=$(git rev-parse --abbrev-ref HEAD)
    
    if [[ $hotfix_branch == *"hotfix"* ]]; then
    
        # Merge hotfix to rcandidate 
        git checkout rcandidate
        git merge $hotfix_branch --no-commit
        
        echo -e "HOTFIX [$hotfix_tag][$repo#<issue_number>]: brief description of the hotfix being solved.\n" > $hotfix_file
        
        if [ -z $EDITOR ]; then 
            vim $hotfix_file
        else 
            $EDITOR $hotfix_file
        fi
        
        git commit --file=$hotfix_file --allow-empty
        git tag $hotfix_tag
    
        # Merge hotfix to develop
        git checkout develop
        git merge $hotfix_branch --no-commit
        git commit --file=$hotfix_file --allow-empty
        git checkout rcandidate
        git push --all
        git push --tags
    else
        echo "The current branch: $hotfix_branch does not seems to be a hotfix branch"
    fi
done

cd $run_dir
git checkout rcandidate

echo -e "HOTFIX LOG AT TAG: $hotfix_tag\n">> history/$hotfix_file

for repo in "$@"
do
    head -n1 $repo/$hotfix_file >> history/$hotfix_file
    git add $repo 
    rm $repo/$hotfix_file
done

git commit --file=history/$hotfix_file
git tag $hotfix_tag
git push --all
git push --tags
