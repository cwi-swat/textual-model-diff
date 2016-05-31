#!/bin/sh
rm $3
git diff --no-index --patience --ignore-space-change --ignore-blank-lines --ignore-space-at-eol -U0 $1 $2 >> $3

 
