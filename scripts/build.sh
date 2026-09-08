#!/bin/bash
set -e

# Читаем REGISTRY/OWNER/... из .env, если он есть рядом со скриптом —
# .env.example для того и существует, но раньше ничего его не читало,
# и REGISTRY/OWNER были жёстко зашиты как "your-username" прямо в коде.
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
BASE_IMAGE_NAME="ros2-cuda-base"

# Раньше TARGET был жёстко зашит в "orin-agx", и позиционный аргумент
# ($1) не читался вовсе — `./build.sh x86_64` тихо игнорировал "x86_64"
# и всегда собирал под orin-agx, вопреки тому, что документировано в
# README. Теперь аргумент реально используется.
TARGET="${1:?Usage: $0 <x86_64|orin-agx|orin-nano>}"
PACKAGE_REPO="${DEFAULT_PACKAGE_REPO:-https://github.com/hku-mars/FAST_LIO.git}"
BRANCH="${DEFAULT_BRANCH:-main}"

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
        echo "Unknown target: $TARGET (expected: x86_64, orin-agx, orin-nano)"
        exit 1
        ;;
esac

docker buildx create --name mybuilder --use || true
docker buildx inspect --bootstrap

# Стадия 1: собрать образ с ROS2 Humble + CUDA-тулчейном локально.
# Раньше этого шага не было вовсе — Dockerfile.package (стадия 2)
# получал сырой $BASE_IMAGE от NVIDIA напрямую, в котором нет ROS2, и
# падал на "source /opt/ros/humble/setup.bash: No such file".
echo "Building base ROS2/CUDA image for $TARGET..."
LOCAL_BASE_TAG="${BASE_IMAGE_NAME}:${TARGET}"
docker buildx build \
    --platform $PLATFORM \
    --build-arg BASE_IMAGE=$BASE_IMAGE \
    --build-arg TARGETPLATFORM=$PLATFORM \
    --build-arg CUDA_ARCH=$CUDA_ARCH \
    -f docker/base/Dockerfile \
    -t $LOCAL_BASE_TAG \
    --load \
    .

# Стадия 2: собрать сам пакет поверх base-образа из стадии 1.
echo "Building package image for $TARGET..."
docker buildx build \
    --platform $PLATFORM \
    --build-arg BASE_IMAGE=$LOCAL_BASE_TAG \
    --build-arg REPO_URL=$PACKAGE_REPO \
    --build-arg BRANCH=$BRANCH \
    --build-arg PACKAGE_NAME=fast_lio \
    --build-arg CUDA_ARCH=$CUDA_ARCH \
    -f docker/templates/Dockerfile.package \
    -t $REGISTRY/$OWNER/$IMAGE_NAME:$TARGET-latest \
    --load \
    .

echo "Build complete! Image: $REGISTRY/$OWNER/$IMAGE_NAME:$TARGET-latest"
