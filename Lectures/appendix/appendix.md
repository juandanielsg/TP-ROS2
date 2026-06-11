# Appendix — Extra Exercises

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

This content has been developed as an expansion of the original course documentation. It is provided here as extra material that goes beyond the required scope of work. **It will not be evaluated.** Use it if you want to explore further after completing the main exercises.

---

## 1. Custom Messages — Pose Controller

This exercise introduces custom ROS2 message types and applies them to a minimal closed-loop controller. You will define a message, build a publisher that reads odometry and sends pose commands, and a subscriber that computes and publishes the required velocity.

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

Add a node to your existing `turtlebot4_python_tutorials` package that publishes `PoseTarget` messages on `/pose_target`. Hardcode a fixed desired pose (for example `x=1.0`, `y=0.0`, `theta=0.0`) and read the current pose from `/tbot<N>/odom`.

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

Start with `k_linear = 0.3` and `k_angular = 1.0`. Set `linear.x` to zero when the heading error is large (more than ~0.3 rad) so the robot turns in place before moving forward. Stop publishing (send a zero `Twist`) when the distance to the goal falls below a threshold of your choice.

### Step 4 — Test it

```bash
ros2 run turtlebot4_python_tutorials pose_publisher \
    --ros-args -r __ns:=/tbot<N>

ros2 run turtlebot4_python_tutorials pose_controller \
    --ros-args -r __ns:=/tbot<N>
```

Verify the intermediate topic:

```bash
ros2 topic echo /tbot<N>/pose_target
ros2 topic echo /tbot<N>/cmd_vel
```

---

## 2. Programmatic Navigation

This section goes beyond the RViz goal tool and shows how to send navigation goals from Python code using the `nav2_simple_commander` library. It requires a saved map and a running Nav2 stack (see Block 5).

### Sending a goal with BasicNavigator

```python
from geometry_msgs.msg import PoseStamped
from nav2_simple_commander.robot_navigator import BasicNavigator
import rclpy


def main():
    rclpy.init()
    navigator = BasicNavigator(namespace='tbot<N>')

    navigator.waitUntilNav2Active()

    goal = PoseStamped()
    goal.header.frame_id = 'map'
    goal.header.stamp = navigator.get_clock().now().to_msg()
    goal.pose.position.x = 1.0
    goal.pose.position.y = 0.5
    goal.pose.orientation.w = 1.0

    navigator.goToPose(goal)

    while not navigator.isTaskComplete():
        pass

    print('Goal reached.')
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

Add to `package.xml`:

```xml
<depend>nav2_simple_commander</depend>
```

**Exercise — Waypoint sequence**

Write a node using `BasicNavigator` that drives the robot through a sequence of waypoints. The robot should visit each point in order and log its arrival at each one.

### Navigate and Take a Photo

Combining navigation with the `camera_snapshot` node from `take_picture.md`, you can send the robot to any point on the map and trigger a photo on arrival.

Run the snapshot node in one terminal:

```bash
ros2 run turtlebot4_python_tutorials camera_snapshot --ros-args -r __ns:=/tbot<N>
```

Then extend the navigation node to publish on `take_picture` once the goal is reached:

```python
from geometry_msgs.msg import PoseStamped
from nav2_simple_commander.robot_navigator import BasicNavigator
from std_msgs.msg import Empty
import rclpy
from rclpy.qos import QoSProfile


def main():
    rclpy.init()
    navigator = BasicNavigator(namespace='tbot<N>')

    trigger_pub = navigator.create_publisher(
        Empty, '/tbot<N>/take_picture', QoSProfile(depth=1))

    navigator.waitUntilNav2Active()

    goal = PoseStamped()
    goal.header.frame_id = 'map'
    goal.header.stamp = navigator.get_clock().now().to_msg()
    goal.pose.position.x = 1.0
    goal.pose.position.y = 0.5
    goal.pose.orientation.w = 1.0

    navigator.goToPose(goal)

    while not navigator.isTaskComplete():
        pass

    trigger_pub.publish(Empty())
    navigator.get_logger().info('Goal reached; photo triggered.')

    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

> The snapshot node and the navigation node are independent and communicate only through the `take_picture` topic. You can swap out either without changing the other.

**Exercise — Photo mission**

Extend the waypoint sequence exercise so that the robot takes a photo at each waypoint before moving on to the next.
