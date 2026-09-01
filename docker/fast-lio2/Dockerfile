ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS builder

ARG CUDA_ARCH

WORKDIR ${ROS_WS}/src
RUN git clone --recursive --depth 1 -b main https://github.com/hku-mars/FAST_LIO.git

RUN apt-get update && \
    rosdep install --from-paths ${ROS_WS}/src -i -y --rosdistro humble \
    --skip-keys=libpcl-all-dev

WORKDIR ${ROS_WS}
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
    colcon build \
        --packages-select fast_lio \
        --cmake-args \
            -DCUDA_ARCH=${CUDA_ARCH} \
            -DCMAKE_BUILD_TYPE=Release"

FROM ${BASE_IMAGE} AS final

COPY --from=builder ${ROS_WS}/install ${ROS_WS}/install

RUN echo "source /opt/ros/humble/setup.bash && source ${ROS_WS}/install/setup.bash" >> /root/.bashrc

WORKDIR ${ROS_WS}
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/bin/bash"]
