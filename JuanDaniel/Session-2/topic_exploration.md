# Topic Exploration — TurtleBot4

**What you will do:** explore the topics published by your TurtleBot4 using command-line tools, understand what each sensor provides, and publish your first message from the terminal.

---

## Prerequisites

- ROS2 Humble sourced and workspace built (see `first_node.md`)
- TurtleBot4 powered on and reachable (replace `<N>` throughout)

---

## 1. Discovering Topics

Run the following and deduce from the help text which sub-command lists all active topics:

```bash
ros2 topic --help
```

Once found, run it. You should see several dozen topics prefixed with `/tbot<N>/`.

---

## 2. The Battery Topic

**Find the battery topic:**

```bash
ros2 topic list | grep battery
```

**Read its current value** (be patient; the battery state is published at low frequency):

```bash
ros2 topic echo /tbot<N>/battery_state
```

**Inspect the message type in detail:**

```bash
ros2 topic info /tbot<N>/battery_state
ros2 interface show sensor_msgs/msg/BatteryState
```

Questions to answer:
- In what unit is battery capacity expressed?
- What does the `voltage` field represent?
- What is the meaning of the `power_supply_status` field?

---

## 3. Topic Bandwidth

`ros2 topic bw` measures how much data flows through a topic per second. Try it on a high-frequency topic:

```bash
ros2 topic bw /tbot<N>/scan
```

Then on a low-frequency one:

```bash
ros2 topic bw /tbot<N>/battery_state
```

Why is the LIDAR bandwidth much higher? What does this imply for node design?

---

## 4. Exploring Key Topics

For each topic below, use `ros2 topic echo` and `ros2 interface show` to understand what it publishes. Answer the question next to each one.

| Topic | Question |
|-------|----------|
| `/tbot<N>/imu` | What does the IMU measure? What are its units? |
| `/tbot<N>/cliff_intensity` | When would this sensor trigger? |
| `/tbot<N>/dock_status` | How can you tell the robot is docked? |
| `/tbot<N>/hazard_detection` | What types of hazards are detected? |
| `/tbot<N>/ip` | What information does this publish? |
| `/tbot<N>/joy` | What does this topic carry when you press a joystick button? |
| `/tbot<N>/wheel_vels` | In what unit are the wheel velocities expressed? |
| `/tbot<N>/diagnostics` | What does this topic summarise? |

To inspect the message type of any topic:

```bash
ros2 topic info /tbot<N>/<topic_name>
ros2 interface show <message_type>
```

---

## 5. Odometry from the Command Line

The `/tbot<N>/odom` topic provides position and orientation estimates. Echo it and answer:

- What are the types of the fields inside `pose`? (`PoseWithCovariance`, `Pose`, `Point`, `Quaternion`)
- What does the `covariance` field represent?
- What is the difference between `pose` and `twist` in this message?

Orientation in ROS2 is expressed as a **quaternion**, not a simple angle. Several systems exist (Euler angles, rotation matrices, quaternions). You can convert between them using this tool: https://www.andre-gaschler.com/rotationconverter/

---

## 6. Publishing from the Terminal

You can publish to any topic directly from the terminal without writing a node. Use this to move the robot:

```bash
ros2 topic pub --once /tbot<N>/cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.2, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```

The robot has a short latency; you may need to publish several times before it responds. Use `--rate 5` instead of `--once` to publish continuously at 5 Hz.

- What happens if you set `linear.x` to a negative value?
- What field controls rotation? Which axis?
- How do you make the robot stop?

---

## 7. Exercise — Battery Monitoring Node

Write a Python node that subscribes to `/tbot<N>/battery_state` and logs the following fields on every message, including their units:

- Voltage
- Temperature
- Remaining capacity
- Charge percentage

Use the subscriber pattern from `first_node.md`. The message type is `sensor_msgs/msg/BatteryState`.

```python
from sensor_msgs.msg import BatteryState
```

Note: the `percentage` field is in the range 0.0–1.0; multiply by 100 to display it as a percentage.

Expected log output format:

```
[INFO] [battery_monitor]: Voltage: 16.34 <?> | Temp: 28.1 <?> | Capacity: 1.83 <?> | Charge: 87.4 <?>
```
