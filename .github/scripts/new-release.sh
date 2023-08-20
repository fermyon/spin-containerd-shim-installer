#!/usr/bin/env bash

read -p "Enter shim version (ex: 0.5.1): " TAG

if [[ ! "$TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]$ ]]; then
  echo "Tag did not match pattern '[0-9]+.[0-9]+.[0-9]+'"
  exit 1
fi

BRANCH="release/v$(echo $TAG | cut -d '.' -f 1-2)"

# switch to latest main
git checkout main
git pull

# create the branch
git checkout -b $BRANCH

# adjust the versions
yq -i ".version = \"${TAG}\"" ./chart/Chart.yaml
yq -i ".appVersion = \"${TAG}\"" ./chart/Chart.yaml

# add the change, commit and tag it
git add ./chart/Chart.yaml
git commit -m "creating release branch for ${TAG}"
