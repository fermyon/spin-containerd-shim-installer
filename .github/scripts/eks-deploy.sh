#!/usr/bin/env bash

set -e

LOGIN=false
BUILD_AND_PUSH=false
PUSH_MANIFEST=false
PUSH_CHART=true

SHIM_VERSION="0.8.0"
ECR_ID="709825985650"
ECR_REGION="us-east-1"
ECR_HOST="$ECR_ID.dkr.ecr.$ECR_REGION.amazonaws.com"

INSTALLER_IMAGE="$ECR_HOST/fermyon/spin-installer-image:$SHIM_VERSION"
INSTALLER_IMAGE_ARM64="$ECR_HOST/fermyon/spin-installer-image:$SHIM_VERSION-arm64"
INSTALLER_IMAGE_AMD64="$ECR_HOST/fermyon/spin-installer-image:$SHIM_VERSION-amd64"

login() {
  # login to aws using a session
  echo "Enter MFA code: "
  read mfa_code
  eval "$(aws-session $mfa_code)"

  echo "Authenticating to AWS ECR..."
  token=$(aws ecr get-login-password --region $ECR_REGION)

  # login to docker registry
  echo $token | docker login \
    --username AWS \
    --password-stdin $ECR_HOST
  # login to helm registry
  echo $token | helm registry login \
    --username AWS \
    --password-stdin $ECR_HOST
}

if [ "$LOGIN" = true ]; then
  login
fi

if [ "$BUILD_AND_PUSH" = true ]; then
  echo "Building docker images..."
  docker build \
    --provenance false \
    --platform "linux/arm64" \
    --build-arg "SHIM_VERSION=$SHIM_VERSION" \
    --tag "$INSTALLER_IMAGE_ARM64" \
    --push \
    ./image

  docker build \
    --provenance false \
    --platform "linux/amd64" \
    --build-arg "SHIM_VERSION=$SHIM_VERSION" \
    --tag "$INSTALLER_IMAGE_AMD64" \
    --push \
    ./image
fi

if [ "$PUSH_MANIFEST" = true ]; then
  echo "Building multi-platform manifest..."
  docker manifest create --amend \
    "$INSTALLER_IMAGE" \
    "$INSTALLER_IMAGE_ARM64" \
    "$INSTALLER_IMAGE_AMD64"

  echo "Annotating multi-platform manifests..."
  docker manifest annotate \
    "$INSTALLER_IMAGE" \
    "$INSTALLER_IMAGE_ARM64" \
    --arch arm64 \
    --os linux

  docker manifest annotate \
    "$INSTALLER_IMAGE" \
    "$INSTALLER_IMAGE_AMD64" \
    --arch amd64 \
    --os linux

  echo "Pushing manifest..."
  docker manifest push "$INSTALLER_IMAGE"
fi

if [ "$PUSH_CHART" = true ]; then
  echo "Building helm chart..."
  helm package ./chart \
    --version "$SHIM_VERSION" \
    --app-version "$SHIM_VERSION-eks"

  echo "Pushing helm chart..."
  # the last part of the chart name is apparently inferred from package name
  helm push \
    ./spin-containerd-shim-installer-$SHIM_VERSION.tgz \
    "oci://$ECR_HOST/fermyon"
fi
