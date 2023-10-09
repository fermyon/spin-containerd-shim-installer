#!/usr/bin/env bash

set -e

VERSION=0.8.0
ECR_HOST=709825985650.dkr.ecr.us-east-1.amazonaws.com
ECR_REPO=$ECR_HOST/fermyon/fermyon-spin
DOCKER_IMAGE=$ECR_REPO/installer-image:$VERSION
HELM_CHART=$ECR_REPO/helm-chart:$VERSION

# DOCKER_IMAGE=709825985650.dkr.ecr.us-east-1.amazonaws.com/fermyon/fermyon-spin/installer-image:0.8.0
# HELM_CHART=709825985650.dkr.ecr.us-east-1.amazonaws.com/fermyon/fermyon-spin/helm-chart:0.8.0

# login to aws using a session
# eval "$(aws-session <mfa_code>)

echo "Authenticating to AWS ECR..."
token=$(aws ecr get-login-password --region us-east-1)

# login to docker registry
echo $token | docker login \
  --username AWS \
  --password-stdin $ECR_HOST
# login to helm registry
echo $token | helm registry login \
  --username AWS \
  --password-stdin $ECR_HOST

echo "Building docker image..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg SHIM_VERSION=$VERSION \
  --tag $DOCKER_IMAGE \
  ./image

echo "Building helm chart..."
helm package ./chart \
  --version $VERSION \
  --app-version "$VERSION-eks"

echo "Pushing docker image..."
docker push $DOCKER_IMAGE

echo "Pushing helm chart..."
helm push \
  ./spin-containerd-shim-installer-$VERSION.tgz \
  oci://$HELM_CHART
