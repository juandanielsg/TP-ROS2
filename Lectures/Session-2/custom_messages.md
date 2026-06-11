# Custom Messages — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**What this session covers:** defining your own ROS2 message types, building them, and using them in a publisher/subscriber pair.

---

## 1. Why Custom Messages

ROS2 ships with standard message packages that cover the majority of common data types:

| Package | Typical contents |
|---------|-----------------|
| `std_msgs` | Primitives: `Bool`, `Int32`, `Float64`, `String`, … |
| `geometry_msgs` | Poses, velocities, transforms, points |
| `sensor_msgs` | LIDAR scans, images, IMU, battery state |
| `nav_msgs` | Odometry, occupancy grids, paths |

When none of these fit your data exactly, you define your own `.msg` file. The build system generates the corresponding Python and C++ code automatically.

---

## 2. Message Definition Syntax

A `.msg` file is a plain-text list of typed fields, one per line:

```
string  label
float64 value
bool    is_valid
```

Available primitive types: `bool`, `byte`, `char`, `float32`, `float64`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `string`.

You can also nest existing message types as fields:

```
std_msgs/Header header
geometry_msgs/Point position
float32         confidence
```

And declare fixed or variable-length arrays:

```
float32[3]  rgb           # fixed array of 3 elements
string[]    labels        # variable-length array
```

---

## 3. Package Layout

Custom message definitions must live in a **dedicated package** that contains only interface files — no Python or C++ node code. This keeps the interface decoupled from any implementation and lets other packages depend on it cleanly.

```
my_msgs/
├── msg/
│   └── MyMessage.msg     ← one file per message type
├── CMakeLists.txt
└── package.xml
```

Message file names use **UpperCamelCase**. The generated Python class has the same name.

---

## 4. Exercise — Pose Controller

You will build a minimal closed-loop controller split across three pieces:

1. A **custom message** that carries the current and desired poses together.
2. A **publisher node** that sends that message.
3. A **subscriber node** that reads the message and publishes the velocity command needed to reach the desired pose.

```
[ pose publisher ] ──/pose_target──▶ [ controller node ] ──/cmd_vel──▶ [ robot ]
```

### Step 1 — Define the message

Create a new package named `turtlebot4_msgs` with the following layout:

```
turtlebot4_msgs/
├── msg/
│   └── PoseTarget.msg
├── CMakeLists.txt
└── package.xml
```

The message carries two 2D poses:

```
geometry_msgs/Pose2D current
geometry_msgs/Pose2D desired
```

`Pose2D` has three fields: `x` (metres), `y` (metres), and `theta` (radians).

In `package.xml`, declare:

```xml
<buildtool_depend>rosidl_default_generators</buildtool_depend>
<exec_depend>rosidl_default_runtime</exec_depend>
<depend>geometry_msgs</depend>
<member_of_group>rosidl_interface_packages</member_of_group>
```

In `CMakeLists.txt`, register the message with the build system:

```cmake
find_package(rosidl_default_generators REQUIRED)
find_package(geometry_msgs REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/PoseTarget.msg"
  DEPENDENCIES geometry_msgs
)
```

Build the package and source the workspace before moving on.

### Step 2 — Write the publisher

Add a node to your existing `turtlebot4_python_tutorials` package that publishes `PoseTarget` messages on `/pose_target`. For this exercise, hardcode a fixed desired pose (for example `x=1.0`, `y=0.0`, `theta=0.0`) and read the current pose from `/tbot<N>/odom`.

The `odom` message type is `nav_msgs/msg/Odometry`. The relevant fields are:

```
pose.pose.position.x
pose.pose.position.y
pose.pose.orientation   ← quaternion; convert to theta with a utility function
```

To convert a quaternion to a yaw angle, use `tf_transformations`:

```python
from tf_transformations import euler_from_quaternion
```

`euler_from_quaternion` takes a list `[x, y, z, w]` and returns `(roll, pitch, yaw)`. The yaw is the heading angle in radians.

### Step 3 — Write the subscriber/controller

Add a second node that subscribes to `/pose_target` and publishes a `geometry_msgs/msg/Twist` on `cmd_vel`.

On each received message, compute the velocity command using a simple proportional controller:

| Quantity | Formula |
|----------|---------|
| Distance to goal | `sqrt((desired.x - current.x)^2 + (desired.y - current.y)^2)` |
| Desired heading | `atan2(desired.y - current.y, desired.x - current.x)` |
| Heading error | `desired_heading - current.theta` |
| `linear.x` | `k_linear * distance` |
| `angular.z` | `k_angular * heading_error` |

Start with `k_linear = 0.3` and `k_angular = 1.0`. Set `linear.x` to zero when the heading error is large (more than ~0.3 rad) so the robot turns in place before moving forward.

Stop publishing velocity (send a zero `Twist`) when the distance to the goal is below a threshold of your choice.

### Step 4 — Test it

Run the two nodes with the robot's namespace:

```bash
ros2 run turtlebot4_python_tutorials pose_publisher \
    --ros-args -r __ns:=/tbot<N>

ros2 run turtlebot4_python_tutorials pose_controller \
    --ros-args -r __ns:=/tbot<N>
```

Verify the intermediate topic with:

```bash
ros2 topic echo /tbot<N>/pose_target
ros2 topic echo /tbot<N>/cmd_vel
```

The robot should rotate to face the goal and then drive toward it.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|-------------|
| `ModuleNotFoundError` when importing the message | Package not built, or `install/local_setup.bash` not sourced |
| `Unknown message type` in `ros2 topic echo` | Same as above — source the workspace overlay |
| Build fails with `rosidl` error | `CMakeLists.txt` or `package.xml` missing the `rosidl_generate_interfaces` call |
| Field name collision | Field names must be `snake_case`; CamelCase names are rejected by the parser |
