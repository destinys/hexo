#!/bin/bash
if [ !-n $1 ];then
  echo "Usage: sh 1key2git.sh comment"
else
git add .
git commit -m $1
git push blog
fi
