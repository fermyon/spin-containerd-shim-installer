#!/usr/bin/env bash

TAG="0.6.0"

# switch to latest main
git checkout main
git pull

# create the branch
git checkout -b "release/v${TAG}"

# chart_version="$(yq '.version' < ./chart/Chart.yaml)"
# app_version="$(yq '.appVersion' < ./chart/Chart.yaml)"

# adjust the versions
yq -i ".version = \"${TAG}\"" ./chart/Chart.yaml
yq -i ".appVersion = \"${TAG}\"" ./chart/Chart.yaml

# add the change, commit and tag it
git add ./chart/Chart.yaml
git commit -m "creating release branch for ${TAG}"
git tag "v${TAG}"
