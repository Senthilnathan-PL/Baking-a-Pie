#!/bin/bash
#set -e kills the bash script even if any one of the command fails to return non 
# -zero exit code (which means failure Linux)
set -e

# Source ROS base
source /opt/ros/jazzy/setup.bash

# Source your workspace (once you add nodes, this activates them)
source /root/ros2_ws/install/setup.bash

# Run whatever command was passed (or bash by default)
exec "$@"
