#!/usr/bin/env bash

set -e

LOGIN=false
DOCKER_BUILD=false
DOCKER_PUSH=false

SHIM_VERSION="0.8.0"
ECR_ID="709825985650"
ECR_REGION="us-east-1"
ECR_HOST="$ECR_ID.dkr.ecr.$ECR_REGION.amazonaws.com"
ECR_REPO="$ECR_HOST/fermyon/fermyon-spin"
DOCKER_TAG="$ECR_REPO:$SHIM_VERSION"
HELM_CHART="$ECR_REPO"


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

declare -a architectures=("amd64" "arm64")
declare -a tags=()
for arch in "${architectures[@]}"
do
  tag="$DOCKER_TAG-$arch-1"
  if [ "$DOCKER_BUILD" = true ]; then
    echo "Building docker image for $arch..."
    docker build \
      --provenance false \
      --platform "linux/$arch" \
      --build-arg "SHIM_VERSION=$SHIM_VERSION" \
      --tag "$tag" \
      ./image
  fi

  if [ "$DOCKER_PUSH" = true ]; then
    echo "Pushing docker image for $arch..."
    docker push "$tag"
  fi

  tags+=("$tag")
done

echo "Building manifest..."
docker manifest create \
  --amend \
  $DOCKER_TAG \
  "${tags[@]}"
for i in "${!architectures[@]}"
do
  echo "Annotating manifest for ${architectures[$i]}..."
  docker manifest annotate \
    "$DOCKER_TAG" \
    "${tags[$i]}" \
    --arch "${architectures[$i]}" \
    --os linux
done
echo "Pushing manifest..."
# docker manifest push $DOCKER_TAG

# echo "Building helm chart..."
# helm package ./chart \
#   --version $SHIM_VERSION \
#   --app-version "$SHIM_VERSION-eks"

# echo "Pushing helm chart..."
# helm push \
#   ./spin-containerd-shim-installer-$SHIM_VERSION.tgz \
#   oci://$HELM_CHART
