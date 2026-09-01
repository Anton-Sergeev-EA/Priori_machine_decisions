#!/bin/bash
set -e

IMAGE_NAME=$1
PLATFORM=${2:-linux/amd64}

if [ -z "$IMAGE_NAME" ]; then
    echo "Usage: $0 <image_name> [platform]"
    echo "Example: $0 ghcr.io/username/ros2-cuda-package:x86_64-latest linux/amd64"
    exit 1
fi

echo "Testing image: $IMAGE_NAME on platform: $PLATFORM"

echo "Checking FAST-LIO2 package."
docker run --rm --platform $PLATFORM $IMAGE_NAME \
    "source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash && ros2 pkg list | grep fast_lio" \
    || { echo "FAST-LIO2 not found!"; exit 1; }
echo "FAST-LIO2 found"

# Проверка CUDA (только для x86, т.к. нужен --gpus all).
if [[ $PLATFORM == linux/amd64 ]]; then
    echo "Checking CUDA on x86_64."
    docker run --rm --gpus all $IMAGE_NAME \
        "nvidia-smi" \
        || { echo "CUDA not available!"; exit 1; }
    echo "CUDA is available"
elif [[ $PLATFORM == linux/arm64 ]]; then
    echo "Skipping CUDA test on ARM64 (requires Jetson hardware)"
fi

echo "Checking architecture."
ARCH=$(docker run --rm --platform $PLATFORM $IMAGE_NAME "uname -m")
echo "Architecture: $ARCH"

echo "All tests passed!"
