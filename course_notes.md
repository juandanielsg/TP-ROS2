# ROS Introduction Course — 6 Sessions

---

## Course Plan

### Session 1 — Introduction & Discovery
- Introduction to ROS (1h)
- Discovery and connections (install)
- Power on the TurtleBot
- Discovery of RViz
- Explanation of the work architecture
- Explanation of evaluation: a slideware to fill in progressively over the 3 days (photos/videos)

### Session 2 — Topics & First Node
- Discovery of topics
- Basic ROS2 commands (`ros2 topic`, etc.)
- Workspace setup
- First ROS node (see book)
- Writing a TurtleBot monitoring node:
  - Display
  - Battery
  - Bumpers
  - Buttons
  - Joypad
- rqt graphs (review book and all notions)

### Session 3 — Robot Control
- Keyboard teleoperation
- Joystick/controller teleoperation
- Using parameters

### Session 4 — Odometry & Obstacle Avoidance
- Odometry: understanding the odom node
- A ROS node to reach a given point using odometry
- Reach a point using odometry while avoiding obstacles with bumper
- Reach a point using odometry while avoiding obstacles with LIDAR
- Then use the Navigator (automated)

### Session 5 — Navigation & SLAM
- Navigation / SLAM
- Map building and cleanup
- Mission: click on the map, the robot goes and takes a photo

### Session 6 — Presentations
- 15-minute presentation slideshow, review of the 3 days with photos and videos

---

## Infrastructure

### WiFi Network
| Parameter | Value |
|-----------|-------|
| SSID | `RHOBAN_100` |
| Password | `h12D!5j_` |
| Router address | `192.168.13.1` |
| Router password | `RhobanW00dSt0ck` |

### PCs
| Hostname | MAC | IP |
|----------|-----|----|
| ros-pc1 | 64:5D:86:C7:17:D5 | 192.168.13.103 |
| ros-pc2 | D4:25:8B:93:30:0F | 192.168.13.105 |
| ros-pc3 | 64:5D:86:C7:17:C6 | 192.168.13.107 |
| ros-pc4 | 4C:1D:96:38:B4:4F | 192.168.13.108 |
| ros-pc5 | 4C:1D:96:39:3D:D4 | 192.168.13.111 |

PC login: `etudiant` / `_turtlebot4`

### TurtleBots
| Robot | Raspberry IP | Create3 IP | Notes |
|-------|-------------|------------|-------|
| Turtle 1 | 192.168.13.114 | 192.168.13.115 | **Needs physical reassembly** |
| Turtle 2 | 192.168.13.101 | 192.168.13.102 | — |
| Turtle 3 | 192.168.13.109 | 192.168.13.110 | — |
| Turtle 4 | 192.168.13.100 | 192.168.13.104 | **Camera not working** |
| Turtle 5 | 192.168.13.116 | 192.168.13.117 | — |

Raspberry login: `ubuntu` / `turtlebot4` (do not connect directly to the Create3)

---

## Per-Robot Status

### Turtle 1
- **Done:** —
- **Known issues:** Needs physical reassembly (`remonter le robot 1`)
- **Left to try:** Everything pending reassembly

### Turtle 2
- **Done:** Network connectivity (assumed stable)
- **Known issues:** General WiFi reconnection instability (shared with all robots)
- **Left to try:** Camera, SLAM, controller pairing

### Turtle 3
- **Done:** Network connectivity (assumed stable)
- **Known issues:** General WiFi reconnection instability
- **Left to try:** Camera, SLAM, controller pairing

### Turtle 4
- **Done:** Network connectivity
- **Known issues:** **Camera not working** (seen working only once — cause unknown)
- **Left to try:** Diagnose and fix camera; SLAM, controller pairing

### Turtle 5
- **Done:** Network connectivity (assumed stable)
- **Known issues:** General WiFi reconnection instability
- **Left to try:** Camera, SLAM, controller pairing

### General Issues (all robots)
- **Battery:** Critical — always turn off the LIDAR when not in use
- **Docked behavior:** The TurtleBot behaves differently when docked (power saving mode)
- **WiFi driver:** Raspberry Pi WiFi (brcmfmac) tends to disconnect; workaround:
  ```bash
  sudo rmmod brcmfmac
  sudo modprobe brcmfmac roamoff=1
  sudo nmcli con up id "netplan-wlan0-RHOBAN"
  ```
  Permanent fix candidate: add `roamoff=1` to `/etc/modprobe.d/brcmfmac.conf`
- **Create3 reflexes:** Motor reflexes (bump, etc.) interfere with manual control — disable them:
  ```bash
  ros2 param set /motion_control reflexes_enable false
  # or per-reflex:
  ros2 param set /motion_control reflexes.REFLEX_BUMP false
  ```
  Ref: https://iroboteducation.github.io/create3_docs/api/reflexes/

---

## What Has Been Done

| Task | Status |
|------|--------|
| VM/Ubuntu setup | Done |
| ROS2 Humble installation | Done |
| TurtleBot unboxing + initial setup | Done |
| RViz launch (model & robot views) | Done |
| Keyboard teleoperation | **OK** — `ros2 run teleop_twist_keyboard teleop_twist_keyboard` |
| SLAM map building (launch) | Tried — map appears after a delay |
| SLAM map saving | Partial — saving without name works; naming fails |
| Controller (Bluetooth) pairing | Attempted — `bluetoothctl` / `scan on` |
| First ROS node | **TODO** |
| Disable Create3 reflexes | Intermittent — command works inconsistently |

---

## Commands Reference

### RViz
```bash
ros2 run rviz2 rviz2
ros2 launch turtlebot4_viz view_model.launch.py   # static model view
ros2 launch turtlebot4_viz view_robot.launch.py   # live robot view (use base_link frame)
```
In RViz: set frame to `base_link`, add `/scan` → LaserScan to see LIDAR.

### Keyboard teleoperation
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

### Topic exploration
```bash
ros2 topic list                          # list all topics
ros2 topic echo <topic>                  # print topic data
ros2 topic info <topic>                  # topic details
ros2 topic pub <topic> <type> <data>     # publish from terminal
ros2 topic hz <topic>                    # check publish rate
ros2 topic bw <topic>                    # check bandwidth
ros2 interface show sensor_msgs/msg/BatteryState  # inspect message types
```

### SLAM / Navigation
```bash
ros2 launch turtlebot4_navigation slam.launch.py
# Save map (wait for map to initialize first):
ros2 service call /slam_toolbox/save_map slam_toolbox/srv/SaveMap
```

### Workspace
```bash
source turtlebot4_ws/install/setup.bash
```

### Network (on Raspberry Pi)
```bash
hostname -I                               # show active IPs
nmcli device wifi list                    # list WiFi networks
sudo nmcli device wifi connect RHOBAN_100 --ask
nmcli connection delete id <name>         # forget a connection
journalctl -u NetworkManager.service      # check connection history
```

---

## Remaining TODOs

### Setup
- [ ] Configure remaining robots (network, ROS_DOMAIN)
- [ ] Set ROS_DOMAIN_ID for robot pairs (1, 4, 5)
- [ ] Delete `.tp-ros` from PC1
- [ ] Configure WiFi addresses on the router
- [ ] Check node example dependencies (XML files in the package)
- [ ] Write a script that monitors which robots are online
- [ ] Consider building a Docker image for the course environment

### Course Content
- [ ] Write the first node tutorial (ref: https://turtlebot.github.io/turtlebot4-user-manual/tutorials/first_node_python.html)
- [ ] Write odometry documentation
- [ ] Test all TurtleBot features end-to-end
- [ ] Validate the full SLAM → save map → navigate workflow
- [ ] Test the photo mission (click on map → robot goes and takes photo)
- [ ] Investigate camera failure on Turtle 4 (and generally)
- [ ] Explain how to put multiple nodes in the same package

### Exercise Ideas
- Modify joystick control
- Write a keyboard controller (natural language input?)
- Odometry exercises using `/wheel_vel` and `/wheel_tick` topics
- Elementary behaviors: advance and stop at bumper/IR, turn, etc.
- ROS parameters node
- Setup test suite (passed/failed checks)

---

## Useful Links

| Resource | URL |
|----------|-----|
| TurtleBot4 documentation | https://turtlebot.github.io/ |
| TurtleBot4 source code | https://github.com/turtlebot |
| First node tutorial | https://turtlebot.github.io/turtlebot4-user-manual/tutorials/first_node_python.html |
| Controller setup | https://turtlebot.github.io/turtlebot4-user-manual/setup/basic.html#turtlebot-4-controller-setup |
| ROS2 Humble install | https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html |
| Create3 reflexes API | https://iroboteducation.github.io/create3_docs/api/reflexes/ |
