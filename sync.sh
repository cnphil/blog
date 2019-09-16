#!/bin/bash

source sensitive_variables

rsync -r -a -v -e ssh --delete --exclude 'images' _site/  $BLOGSSHUSER@blog.phil.tw:$BLOGSSHDIR
