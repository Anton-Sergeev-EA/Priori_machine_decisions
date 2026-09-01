# syntax=docker/dockerfile:1.4
# Базовый образ с ROS2 Humble и CUDA Toolkit.

ARG TARGETPLATFORM
ARG BASE_IMAGE

FROM --platform=$TARGETPLATFORM ${BASE_IMAGE} AS base

# Аргументы для архитектуры CUDA.
ARG CUDA_ARCH
ENV CUDA_ARCH=${CUDA_ARCH}

# Отключение интерактивных запросов apt.
ENV DEBIAN_FRONTEND=noninteractive

# Установка ROS2 Humble.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    lsb-release \
    software-properties-common \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Установка ROS2 и инструментов сборки.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-ros-base \
    ros-humble-colcon-common-extensions \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    python3-pip \
    build-essential \
    cmake \
    git \
    wget \
    vim \
    libeigen3-dev \
    libopencv-dev \
    libpcl-dev \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# Инициализация rosdep.
RUN rosdep init && rosdep update || true

# Создание рабочего пространства.
ENV ROS_WS=/ros2_ws
WORKDIR ${ROS_WS}

# Настройка окружения ROS.
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc

# Точка входа.
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/bin/bash"]
