#!/bin/bash
# FAST-LIO entrypoint for xbag runner.
# Expects: --network=host (shares host ROS master + xbag play topics)
# Mounts:  /config/params.yaml (rendered config), /output (record bag)

set -e

source /opt/ros/noetic/setup.bash
source /ws/devel/setup.bash

# 1. Load config and launch algorithm (background)
rosparam load /config/params.yaml
rosrun fast_lio fastlio_mapping &
ALGO_PID=$!
sleep 2

# 2. Record output topics (background)
rosbag record -O /output/record \
  /Odometry /cloud_registered_body &
RECORD_PID=$!

# 3. Wait for SIGINT from host (sent after xbag play finishes)
trap "echo 'Received SIGINT, shutting down...'" INT
wait $ALGO_PID 2>/dev/null || true

# 4. Stop recording (flush bag header)
kill -INT $RECORD_PID 2>/dev/null
wait $RECORD_PID 2>/dev/null || true
