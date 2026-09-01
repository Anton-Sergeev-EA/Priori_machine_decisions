#!/bin/bash
set -e

REGISTRY="ghcr.io"
OWNER="your-username"
IMAGE_NAME="ros2-cuda-package"
TAG=${1:-latest}

echo "$GITHUB_TOKEN" | docker login ghcr.io -u $OWNER --password-stdin

for TARGET in x86_64 orin-agx orin-nano; do
    docker push $REGISTRY/$OWNER/$IMAGE_NAME:$TARGET-$TAG
    echo "Published $REGISTRY/$OWNER/$IMAGE_NAME:$TARGET-$TAG"
done
