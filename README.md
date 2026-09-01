# ROS2 CUDA Cross-Platform Docker Build System.
Система автоматической кросс-платформенной сборки Docker-образов для ROS2-пакетов с поддержкой CUDA.

## Требования.
- Docker 20.10+
- Docker Buildx
- GitHub Actions (или GitLab CI)
- Для нативной сборки: NVIDIA Jetson AGX Orin / Orin Nano с JetPack 6.2.2

## Быстрый старт.
1. Клонирование репозитория.
git clone https://github.com/your-username/ros2-cuda-ci.git
cd ros2-cuda-ci
2. Локальная сборка.
- Сборка для x86_64.
./scripts/build.sh x86_64
- Сборка для Jetson (кросс-сборка).
./scripts/build.sh orin-agx
./scripts/build.sh orin-nano
3. Тестирование.
- Тестирование собранного образа.
./scripts/test_cuda.sh ghcr.io/your-username/ros2-cuda-package:orin-agx-latest linux/arm64
4. Публикация.
export GITHUB_TOKEN=ghp_xxxxx
./scripts/publish.sh latest

## Добавление нового пакета.
1. Создайте новый Dockerfile в docker/your-package/:
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS builder

ARG CUDA_ARCH

WORKDIR ${ROS_WS}/src
RUN git clone --recursive -b main https://github.com/your-org/your-package.git

RUN apt-get update && rosdep install --from-paths . -i -y --rosdistro humble

WORKDIR ${ROS_WS}
RUN source /opt/ros/humble/setup.bash && \
    colcon build --packages-select your_package --cmake-args -DCUDA_ARCH=${CUDA_ARCH}

FROM ${BASE_IMAGE} AS final
COPY --from=builder ${ROS_WS}/install ${ROS_WS}/install
2. Добавьте пакет в матрицу сборки в .github/workflows/build.yml:
matrix:
  include:
    - target: your-target
      base_image: nvcr.io/nvidia/l4t-jetpack:r36.2.0
      cuda_arch: 87

## Мониторинг и метрики.
Метрика	            Источник	      Описание
Время сборки	    GitHub Actions	  Длительность каждого шага
Размер образа	    GitHub Packages	  Размер в реестре
Успешность тестов	GitHub Actions	  Статус пайплайна
Кол-во загрузок	    GitHub Packages	  Статистика использования

## Устранение проблем.
- Проблема: QEMU не эмулирует ARM64.
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
- Проблема: CUDA не доступна в контейнере.
Для x86:
docker run --rm --gpus all your-image nvidia-smi
Для Jetson:
docker run --rm --runtime nvidia your-image nvidia-smi
- Проблема: Недостаточно памяти при кросс-сборке.
Добавьте флаги в Docker Buildx:
docker buildx build --memory=8g --swap=8g ...

## Лицензия.
MIT License

## Автор.
Сергеев Антон Валентинович
kavery@mail.ru
