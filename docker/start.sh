#!/bin/bash

# Allow Docker containers to connect to the host X11 display (needed for Gazebo/RViz2)
xhost +local:docker

# Build the image on first run (or if it doesn't exist yet), then start the container
docker compose up -d

# Open an interactive shell inside the running container
docker exec -it turtlebot4-sim bash
