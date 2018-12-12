#!/bin/bash

git fetch --all
var=$(git diff origin/master)

if [ -z "$var" ]
then
      echo "\$var is empty"
else
      echo "\$var is NOT empty"
fi
