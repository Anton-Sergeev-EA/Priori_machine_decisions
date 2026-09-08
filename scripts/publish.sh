#!/bin/bash
set -e

# См. build.sh — тот же принцип: REGISTRY/OWNER берутся из .env, если он
# есть, вместо того чтобы быть жёстко зашитыми как "your-username".
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

REGISTRY="${REGISTRY:-ghcr.io}"
OWNER="${OWNER:-your-username}"
IMAGE_NAME="ros2-cuda-package"
TAG=${1:-latest}

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set. Export it first (see .env.example)." >&2
    exit 1
fi

echo "$GITHUB_TOKEN" | docker login ghcr.io -u $OWNER --password-stdin

for TARGET in x86_64 orin-agx orin-nano; do
    docker push $REGISTRY/$OWNER/$IMAGE_NAME:$TARGET-$TAG
    echo "Published $REGISTRY/$OWNER/$IMAGE_NAME:$TARGET-$TAG"
done
