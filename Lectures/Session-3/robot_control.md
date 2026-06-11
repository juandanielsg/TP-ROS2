# Robot Control — TurtleBot4

**What you will do:** drive the TurtleBot4 using the keyboard and the joystick controller, then learn how to read and modify the robot's runtime parameters.

---

## Prerequisites

- ROS2 Humble sourced and workspace built (see Session 2)
- TurtleBot4 reachable on the network
- Your robot number (used as namespace, replace `<N>` throughout with your number)

---

## 1. Keyboard Teleoperation

Install the teleop package if not already present:

```bash
sudo apt install ros-humble-teleop-twist-keyboard
```

Then run it, remapping to your robot's namespace:

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard \
    --ros-args -r __ns:=/tbot<N>
```

The terminal will display the key bindings. The robot only moves while the window has focus, so keep it in the foreground.

| Key | Action |
|-----|--------|
| `i` | Forward |
| `,` | Backward |
| `j` / `l` | Rotate left / right |
| `u` / `o` | Diagonal forward |
| `k` | Stop |
| `q` / `z` | Increase / decrease speed |

> **Why the remap?** `teleop_twist_keyboard` publishes on the relative topic `cmd_vel`. With `__ns:=/tbot<N>`, ROS2 resolves this to `/tbot<N>/cmd_vel`, which is the topic your robot listens on. Without the remap, the command goes nowhere.

---

## 2. Joystick Controller

The controller pairs with the **Raspberry Pi** on the robot, not with the PC. Once paired, the robot's built-in `joy2twist` node translates joystick inputs into velocity commands automatically.

### Driving with the controller

| Input | Action |
|-------|--------|
| Hold **L1** or **R1** | Enable movement (deadman switch) |
| **Left joystick** (while holding L1/R1) | Drive and steer |

The deadman switch is intentional: releasing L1/R1 immediately stops the robot.

---

## 3. Using Parameters

ROS2 parameters let you read and modify the configuration of a running node without changing its code or restarting it.

### Useful commands

```bash
ros2 param list <node_name>               # list all parameters of a node
ros2 param get <node_name> <param>        # read a parameter value
ros2 param set <node_name> <param> <val>  # change a parameter at runtime
```

### Practical example — disabling Create3 reflexes

The Create3 base has built-in safety reflexes (e.g. it automatically backs away when it hits something). These interfere with manual control. You can disable them with parameters:

```bash
# List parameters of the motion_control node
ros2 param list /motion_control

# Disable all reflexes at once
ros2 param set /motion_control reflexes_enable false

# Or disable a specific reflex
ros2 param set /motion_control reflexes.REFLEX_BUMP false
```

Full list of available reflexes: https://iroboteducation.github.io/create3_docs/api/reflexes/

> Parameters are reset when the node restarts. To make a change permanent, it needs to be set in a launch file or parameter file.

---

## 4. Observing Motion in RViz

Launch RViz while driving to observe what the robot's sensors report:

```bash
ros2 launch turtlebot4_viz view_robot.launch.py namespace:=tbot<N>
```

Once RViz is open, explore the display and answer the following questions:

- What does the **red point cloud** around the robot represent?
- Open the camera feed by setting the image topic to `/tbot<N>/oakd/rgb/preview/image_raw`. What is superimposed on the image?
- Using the **Add** button on the left panel, add a **TF** plugin and configure it to show only the `base_link` frame.

Then drive the robot (keyboard or joystick) while watching RViz:

- With **Fixed Frame = `base_link`**: what happens to the map and laser scan as the robot moves?
- Switch **Fixed Frame** to `odom` and drive again. What changes?
- What does the term `odom` refer to, and why does this frame matter for navigation?

We will use the `odom` frame extensively in Session 4.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Robot does not move with keyboard | Check the namespace: run `ros2 topic list` and confirm `/tbot<N>/cmd_vel` exists |
| Controller LED blinks but robot doesn't move | Controller not paired with the robot's Raspberry Pi; redo pairing via SSH |
| Robot moves unexpectedly after bumping something | Create3 reflexes are active; disable with `ros2 param set /motion_control reflexes_enable false` |
| `ros2 param list /motion_control` returns nothing | Node not running or wrong namespace; check with `ros2 node list` |
