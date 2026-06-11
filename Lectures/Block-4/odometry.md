# Odometry — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**What you will learn:** what odometry is, how the `/odom` topic works, how to read the robot's position and orientation from it, and how to use it in a node.

---

## Prerequisites

- Sessions 2 and 3 completed
- Comfortable with writing a basic subscriber node (see Session 2)
- Your robot number (replace `<N>` throughout)

---

## 1. What is Odometry?

Odometry is an estimate of the robot's position and orientation in space, computed by integrating wheel movements over time. Every time a wheel turns, the robot infers how far it has moved and in which direction.

Key points to keep in mind:

- The reference frame is `odom`, a fixed frame whose origin is wherever the robot was when it started.
- Odometry **accumulates error** over time. Small measurement errors in wheel slippage add up, so the estimate drifts away from the true position.
- It gives no information about the environment, only about the robot's own movement.

---

## 2. Inspecting the Topic

```bash
# Confirm the topic exists
ros2 topic list | grep odom

# Print incoming messages
ros2 topic echo /tbot<N>/odom

# Check the message type
ros2 topic info /tbot<N>/odom

# Read the full message definition
ros2 interface show nav_msgs/msg/Odometry
```

The message type is `nav_msgs/msg/Odometry`.

---

## 3. The Odometry Message

```
nav_msgs/msg/Odometry
├── header
│   ├── stamp        : timestamp of the measurement
│   └── frame_id     : reference frame ("odom")
├── child_frame_id   : the robot frame ("base_link")
├── pose
│   └── pose
│       ├── position
│       │   ├── x    : meters (forward/backward)
│       │   ├── y    : meters (left/right)
│       │   └── z    : meters (up/down, usually ~0)
│       └── orientation
│           ├── x  ─╮
│           ├── y   │ quaternion
│           ├── z   │ (see Section 4)
│           └── w  ─╯
└── twist
    └── twist
        ├── linear
        │   └── x    : current forward velocity (m/s)
        └── angular
            └── z    : current rotation rate (rad/s)
```

In practice you will mostly use `pose.pose.position.x/y` for position and `pose.pose.orientation` for heading.

---

## 4. Orientation and Quaternions

ROS2 expresses orientation as a **quaternion** `(x, y, z, w)` rather than a single angle. This avoids ambiguities that arise with Euler angles (gimbal lock) and works uniformly in 3D.

For a ground robot moving in a flat plane, only rotation around the vertical axis (yaw) matters. The quaternion simplifies to:

```
x = 0
y = 0
z = sin(yaw / 2)
w = cos(yaw / 2)
```

To convert back to a yaw angle in Python:

```python
import math

def quaternion_to_yaw(orientation):
    # orientation is a geometry_msgs/msg/Quaternion
    siny_cosp = 2.0 * (orientation.w * orientation.z + orientation.x * orientation.y)
    cosy_cosp = 1.0 - 2.0 * (orientation.y ** 2 + orientation.z ** 2)
    return math.atan2(siny_cosp, cosy_cosp)   # result in radians
```

> To experiment with orientation conversions interactively: https://www.andre-gaschler.com/rotationconverter/

---

## 5. Reading Odometry in a Node

The pattern is identical to the button subscriber from Session 2: subscribe to `/odom` and process each message in a callback.

```python
from nav_msgs.msg import Odometry
import math
import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data


def quaternion_to_yaw(orientation):
    siny_cosp = 2.0 * (orientation.w * orientation.z + orientation.x * orientation.y)
    cosy_cosp = 1.0 - 2.0 * (orientation.y ** 2 + orientation.z ** 2)
    return math.atan2(siny_cosp, cosy_cosp)


class OdomReader(Node):

    def __init__(self):
        super().__init__('odom_reader')

        self.create_subscription(
            Odometry,
            'odom',                         # relative (namespace applied at launch)
            self.odom_callback,
            qos_profile_sensor_data)

    def odom_callback(self, msg: Odometry):
        x   = msg.pose.pose.position.x
        y   = msg.pose.pose.position.y
        yaw = quaternion_to_yaw(msg.pose.pose.orientation)

        self.get_logger().info(
            f'Position: x={x:.3f} m  y={y:.3f} m  yaw={math.degrees(yaw):.1f}°'
        )


def main(args=None):
    rclpy.init(args=args)
    node = OdomReader()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

Run it with:

```bash
ros2 run <your_package> odom_reader --ros-args -r __ns:=/tbot<N>
```

Move the robot (keyboard or joystick) and observe how `x`, `y`, and `yaw` change.

### Key concepts

| Concept | What it does here |
|---------|-------------------|
| `nav_msgs/msg/Odometry` | Standard ROS2 message carrying pose and velocity |
| `pose.pose.position` | Robot position in the `odom` frame (meters) |
| `pose.pose.orientation` | Robot heading as a quaternion |
| `twist.twist.linear.x` | Current forward speed (m/s) |
| `twist.twist.angular.z` | Current rotation rate (rad/s) |

---

## 6. Exercises

These exercises build on each other; complete them in order.

**Exercise 1 — Basic movement**

Write a node that makes the robot move forward for 5 seconds, then rotate in place counter-clockwise for 5 seconds. Publish to `cmd_vel` (see the Session 3 teleop for the message type).

**Exercise 2 — LIDAR-guided movement**

Extend the previous node to read the LIDAR (`scan` topic). The robot should:
1. Spin in place.
2. Stop when it faces a clear passage of at least 1 metre.
3. Advance 1 metre.

**Exercise 3 — Observe odometry**

Add odometry logging to the node from Exercise 2 (subscribe to `odom` alongside `scan`). Run the node and explain what each field in the message represents. Does the robot end up where you expect after the sequence?

**Exercise 4 — Go to a target point**

Using odometry as feedback, write a node that drives the robot to a user-supplied position `(x, y)`. The sequence should be:
1. Rotate to face the target.
2. Drive in a straight line to the target.
3. Rotate to reach the target orientation (if provided).

**Exercise 5 — Obstacle avoidance**

Modify the node from Exercise 4 to detect and avoid obstacles on the way to the target.

> **Algorithms to explore.** Several classic approaches exist for reactive obstacle avoidance; here are a few worth investigating before choosing one to implement:
>
> - **Potential field** — the target exerts an attractive force on the robot, each obstacle a repulsive one. The robot follows the resultant. Simple to code, but can get stuck in local minima (dead ends).
> - **Reactive heuristic (turn-and-go)** — if an obstacle is detected ahead, the robot turns by a fixed angle (or until the LIDAR scan shows a clear path), then resumes heading toward the target. Robust and easy to tune.
> - **Wall-following** — when an obstacle is encountered, the robot follows its edge until it can resume heading toward the target. Handles more environments than turn-and-go, but the logic for leaving the wall is trickier.
>
> Choose the approach that seems most interesting or best suited to the lab environment, and implement it.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| No messages on `/tbot<N>/odom` | Robot not running or wrong namespace; check with `ros2 topic list` |
| Position never resets to zero | Odometry origin is set at startup; undock and restart the robot if needed |
| Yaw jumps between +π and −π | This is expected: `atan2` wraps at ±180°, so handle it in your code when computing angle differences |
