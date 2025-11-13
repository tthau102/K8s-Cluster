#!/bin/bash

# Default branch là branch hiện tại
branch=$(git rev-parse --abbrev-ref HEAD)

datenow=$(date +%d/%m/%y-%H:%M:%S)

# Thực hiện commit và push
git add .
git commit -m "$datenow"
git push -u origin $branch --force

echo "Changes pushed to $branch branch"