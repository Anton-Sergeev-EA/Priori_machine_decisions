#!/bin/bash
set -e

REGISTRY="ghcr.io"
OWNER="your-username"
IMAGE_NAME="ros2-cuda-package"
TARGET="orin-agx"  # or x86_64, orin-agx, orin-nano
PACKAGE_REPO="https://github.com/hku-mars/FAST_LIO.git"
BRANCH="main"
CUDA_ARCH="87"

# Определяем базовый образ
case $TARGET in
    x86_64)
        BASE_IMAGE="nvidia/cuda:12.2.0-devel-ubuntu22.04"
        PLATFORM="linux/amd64"
        CUDA_ARCH="86"
        ;;
    orin-agx)
        BASE_IMAGE="nvcr.io/nvidia/l4t-jetpack:r36.2.0"
        PLATFORM="linux/arm64"
        CUDA_ARCH="87"
        ;;
    orin-nano)
        BASE_IMAGE="nvcr.io/nvidia/l4t-jetpack:r36.2.0"
        PLATFORM="linux/arm64"
        CUDA_ARCH="87"
        ;;
    *)
        echo "Unknown target: $TARGET"
        exit 1
        ;;
esac

docker buildx create --name mybuilder --use || true
docker buildx inspect --bootstrap

docker buildx build \
    --platform $PLATFORM \
    --build-arg BASE_IMAGE=$BASE_IMAGE \
    --build-arg REPO_URL=$PACKAGE_REPO \
    --build-arg BRANCH=$BRANCH \
    --build-arg PACKAGE_NAME=fast_lio \
    --build-arg CUDA_ARCH=$CUDA_ARCH \
    -f docker/templates/Dockerfile.package \
    -t $REGISTRY/$OWNER/$IMAGE_NAME:$TARGET-latest \
    --load \
    .

echo "Build complete! Image: $REGISTRY/$OWNER/$IMAGE_NAME:$TARGET-latest"
