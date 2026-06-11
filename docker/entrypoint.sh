#!/bin/bash
set -e

source /opt/ros/humble/setup.bash

# Source the workspace overlay if it has been built
if [ -f /ros_ws/install/setup.bash ]; then
    source /ros_ws/install/setup.bash
fi

exec "$@"
