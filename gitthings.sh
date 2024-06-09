#!/bin/bash 

git add . 
read QUERY_STRING
git commit -m "{`$QUERY_STRING`}" 
git push
