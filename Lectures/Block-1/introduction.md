# Introduction to ROS — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**What this session is about:** a first look at ROS, the robot you will be working with, and the tools you will use throughout the course. By the end you will have powered on a TurtleBot4, visualised its sensors live in RViz, and understood how the pieces fit together.

---

## 1. What is ROS?

**ROS** (Robot Operating System) is not an operating system in the traditional sense. It is a middleware framework that runs on top of Linux. Its job is to let the different software components of a robot communicate with each other, regardless of which programming language they are written in or which computer they run on.

### The three core concepts

| Concept | What it is | Analogy |
|---------|-----------|---------|
| **Node** | A process that does one thing (reads a sensor, controls a motor, builds a map…) | A microservice |
| **Topic** | A named channel on which nodes publish or subscribe to a stream of messages | A radio frequency |
| **Message** | A typed data structure sent over a topic | A packet |

A robot running ROS is a graph of nodes exchanging messages over topics. You never need to worry about sockets, serialisation, or timing: ROS handles all of that.

```
[ camera node ] ──/image──▶ [ processing node ] ──/cmd_vel──▶ [ motor node ]
```

### Why it matters

- **Reuse:** thousands of ready-made nodes exist for sensors, navigation, perception, and more. You rarely start from scratch.
- **Introspection:** you can inspect every message flowing through the system from the command line, at any time, without modifying any code.
- **Hardware independence:** the same navigation stack works on a TurtleBot, a drone, or a robotic arm.

---

## 2. The TurtleBot4

The TurtleBot4 is a research and education robot built from three main components:

| Component | Role |
|-----------|------|
| **iRobot Create3** | The wheeled base (motors, wheels, bumpers, IR sensors, battery) |
| **Raspberry Pi 4** | The on-board computer (runs ROS2, manages the camera and network) |
| **OAK-D Lite camera** | A stereo RGB-D camera mounted on top |

The Create3 also carries a **360° LIDAR** (laser scanner) that measures distances to surrounding objects. It is the main sensor for mapping and obstacle avoidance.

### How it connects to your PC

Your PC and the TurtleBot4 are on the same WiFi network. ROS2 uses multicast to discover nodes automatically: once both are on the network and share the same **ROS_DOMAIN_ID**, your PC sees the robot's topics as if they were local.

```
[ Your PC ] ── WiFi (RHOBAN_100) ── [ Raspberry Pi ] ── USB ── [ Create3 ]
```

You do not log into the robot to run your nodes. You write and run them on your PC; they communicate with the robot's nodes over the network transparently.

---

## 3. Powering on the TurtleBot4

Place the robot on its docking station. It will power on automatically when it detects the charging contact. The ring of LEDs will animate and the robot will play a short melody.

Alternatively, you can power it on off the dock by pressing the **centre button** (large circular button on top) briefly.

Wait about 30 seconds for the Raspberry Pi to boot and ROS2 to start. You can confirm the robot is ready when topics appear in your terminal (see Section 4).

> When you are done, always **turn the LIDAR off** before leaving the robot unattended. It draws significant power and will drain the battery even while charging.

To turn the robot off: hold the centre button for 10 seconds until it plays a short melody and the LEDs go dark.

---

## 4. Your first ROS2 commands

Open a terminal on your PC, source ROS2, then try the following.

```bash
source /opt/ros/humble/setup.bash
```

**List all active topics:**

```bash
ros2 topic list
```

You should see several dozen topics prefixed with `/tbot<N>/` (one prefix per robot on the network). Each topic is a live data stream from the robot.

**Print data from a topic:**

```bash
ros2 topic echo /tbot<N>/battery_state
```

This streams the battery status in real time. Press `Ctrl+C` to stop.

**Get details about a topic:**

```bash
ros2 topic info /tbot<N>/battery_state
```

**Inspect a message type:**

```bash
ros2 interface show sensor_msgs/msg/BatteryState
```

These four commands (`list`, `echo`, `info`, `interface show`) are the core of your ROS2 debugging toolkit. You will use them constantly.

---

## 5. Discovering RViz

RViz is ROS2's built-in visualisation tool. It lets you see sensor data, robot models, maps, and transforms in a 3D view, without writing any code.

Launch it with the TurtleBot4 robot model:

```bash
ros2 launch turtlebot4_viz view_robot.launch.py namespace:=tbot<N>
```

### Setting up the view

1. In the **Displays** panel on the left, set **Fixed Frame** to `base_link`.
2. Click **Add → By Topic**, find `/tbot<N>/scan`, and select **LaserScan**. You should see a ring of red dots around the robot (the LIDAR reading).
3. Click **Add → By Topic**, find `/tbot<N>/oakd/rgb/preview/image_raw`, and select **Image**. A small camera feed window will appear (only when the robot is undocked).

### What you are seeing

| Display | What it shows |
|---------|--------------|
| Robot model | The 3D URDF model of the TurtleBot4 |
| LaserScan (`/scan`) | Distance measurements from the 360° LIDAR |
| Image (`/oakd/…`) | Live RGB feed from the OAK-D camera |

Try moving an object in front of the robot and watch the LIDAR scan react in real time.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| `ros2 topic list` returns nothing | ROS2 not sourced, or robot not yet booted. Wait 30 s and retry |
| Topics appear but with a different prefix | Another group's robot; check your robot number and look for `/tbot<N>/` |
| RViz launches but the model is invisible | Wrong Fixed Frame; set it to `base_link` |
| No camera image in RViz | Robot is docked. The camera is inactive while on the charging station (see [docked_mode.md](../General/docked_mode.md)) |
