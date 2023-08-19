#!/usr/bin/env bash

# get the latest tag
TAG="$(git describe --tags `git rev-list --tags --max-count=1`)"

# delete the local tag
git tag -d $TAG

# delete the remote tag
git push origin :refs/tags/$TAG

# retag current commit
git tag $TAG

# push the new tag
git push origin $TAG
