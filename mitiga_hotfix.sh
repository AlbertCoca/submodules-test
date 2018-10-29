#!/bin/bash



hotfix_tag=$1
run_dir=$PWD

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
    
        hotfix_file="hotfix_$hotfix.txt"
       
        # Merge hotfix to rcandidate 
        git checkout rcandidate
        git merge $hotfix_branch --no-commit
        
        echo "HEADER TEST" > $hotfix_file
        
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
    else
        echo "The current branch: $hotfix_branch does not seems to be a hotfix branch"
    fi

done
