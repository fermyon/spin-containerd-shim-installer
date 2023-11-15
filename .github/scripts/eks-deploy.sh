#!/usr/bin/env bash

set -e

LOGIN=false
PRINT_VERSIONS=false

BUILD_IMAGE=false
PUSH_IMAGE_MANIFEST=false

BUILD_PAUSE=false
PUSH_PAUSE_MANIFEST=false

PUSH_CHART=true

SHIM_VERSION="0.8.0"
ECR_ID="709825985650"
ECR_REGION="us-east-1"
ECR_HOST="$ECR_ID.dkr.ecr.$ECR_REGION.amazonaws.com"

INSTALLER_IMAGE="$ECR_HOST/fermyon/spin-installer-image:$SHIM_VERSION"
INSTALLER_IMAGE_ARM64="$ECR_HOST/fermyon/spin-installer-image:$SHIM_VERSION-arm64"
INSTALLER_IMAGE_AMD64="$ECR_HOST/fermyon/spin-installer-image:$SHIM_VERSION-amd64"

PAUSE_IMAGE="$ECR_HOST/fermyon/spin-installer-pause:3.6"
PAUSE_IMAGE_AMD64="$ECR_HOST/fermyon/spin-installer-pause:3.6-amd64"
PAUSE_IMAGE_ARM64="$ECR_HOST/fermyon/spin-installer-pause:3.6-arm64"

login() {

  if [ -z "AWS_SESSION_TOKEN" ]; then
    # login to aws using a session
    echo "Enter MFA code: "
    read mfa_code
    # eval "$(aws-session $mfa_code)"
  fi

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

if [ "$PRINT_VERSIONS" = true ]; then
  echo "INSTALLER_URI: $INSTALLER_IMAGE"
  echo "CHART_URI: $ECR_HOST/fermyon/spin-containerd-shim-installer:$SHIM_VERSION-eksrc1"
fi

if [ "$LOGIN" = true ]; then
  login
fi

if [ "$BUILD_IMAGE" = true ]; then
  echo "Building docker image for installer..."
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

if [ "$BUILD_PAUSE" = true ]; then
  echo "Building docker image for pause..."
  docker build \
    --provenance false \
    --platform "linux/arm64" \
    --tag "$PAUSE_IMAGE_ARM64" \
    --push \
    ./pause

  docker build \
    --provenance false \
    --platform "linux/amd64" \
    --tag "$PAUSE_IMAGE_AMD64" \
    --push \
    ./pause
fi

if [ "$PUSH_IMAGE_MANIFEST" = true ]; then
  echo "Building multi-platform manifest for installer..."
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

if [ "$PUSH_PAUSE_MANIFEST" = true ]; then
  echo "Building multi-platform manifest for pause..."
  docker manifest create --amend \
    "$PAUSE_IMAGE" \
    "$PAUSE_IMAGE_ARM64" \
    "$PAUSE_IMAGE_AMD64"

  echo "Annotating multi-platform manifests..."
  docker manifest annotate \
    "$PAUSE_IMAGE" \
    "$PAUSE_IMAGE_ARM64" \
    --arch arm64 \
    --os linux

  docker manifest annotate \
    "$PAUSE_IMAGE" \
    "$PAUSE_IMAGE_AMD64" \
    --arch amd64 \
    --os linux

  echo "Pushing manifest..."
  docker manifest push "$PAUSE_IMAGE"
fi

if [ "$PUSH_CHART" = true ]; then
  echo "Building helm chart..."
  helm package ./chart \
    --version "$SHIM_VERSION-eksrc3" \
    --app-version "$SHIM_VERSION-eks"

  echo "Pushing helm chart..."
  # the last part of the chart name is apparently inferred from package name
  helm push \
    ./spin-containerd-shim-installer-$SHIM_VERSION-eksrc3.tgz \
    "oci://$ECR_HOST/fermyon"
fi
