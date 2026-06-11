FROM osrf/ros:humble-desktop-full

ENV DEBIAN_FRONTEND=noninteractive

# Add the OSRF Gazebo repository -- required for ignition-fortress
RUN apt-get update && apt-get install -y curl && \
    curl -sSL https://packages.osrfoundation.org/gazebo.key \
        | gpg --dearmor -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
        http://packages.osrfoundation.org/gazebo/ubuntu-stable \
        $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
        | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    ignition-fortress \
    ros-humble-turtlebot4-simulator \
    ros-humble-turtlebot4-desktop \
    ros-humble-turtlebot4-navigation \
    python3-colcon-common-extensions \
    python3-rosdep \
    && rm -rf /var/lib/apt/lists/*

# Bundle the local empty world so `world:=empty` works without internet (Fuel) access
COPY worlds/empty.sdf /opt/ros/humble/share/turtlebot4_ignition_bringup/worlds/empty.sdf

WORKDIR /ros_ws

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "[ -f /ros_ws/install/setup.bash ] && source /ros_ws/install/setup.bash" >> /root/.bashrc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
