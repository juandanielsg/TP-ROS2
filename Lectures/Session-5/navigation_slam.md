# Navigation & SLAM — TurtleBot4

**What you will do:** build a map of the environment using SLAM, then use that map to navigate the robot autonomously to any point, and finally combine navigation with the camera to run a photo-taking mission.

---

## Prerequisites

- Sessions 2–4 completed
- `camera_snapshot` node from `take_picture.md` available in your package
- Your robot number (replace `<N>` throughout)

---

## 1. What is SLAM?

**SLAM** (Simultaneous Localisation and Mapping) lets the robot build a map of its environment while keeping track of where it is within that map. It uses the LIDAR to detect walls and obstacles, and the odometry from Session 4 to estimate movement.

The result is a 2D occupancy grid, a grayscale image where:
- **White** = free space
- **Black** = obstacle
- **Grey** = unknown (not yet explored)

---

## 2. Building a Map

### Launch SLAM

In one terminal, start the SLAM node:

```bash
ros2 launch turtlebot4_navigation slam.launch.py namespace:=tbot<N>
```

In a second terminal, open RViz to watch the map grow in real time:

```bash
ros2 launch turtlebot4_viz view_robot.launch.py namespace:=tbot<N>
```

In RViz, add a **Map** display (Add → By Topic → `/tbot<N>/map`). The map will appear a few seconds after launch, once enough LIDAR data has been collected.

### Drive to explore

Use the keyboard or joystick (Session 3) to drive the robot around the area you want to map. Move slowly and cover every room or corridor; areas the robot never visits will remain grey.

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r __ns:=/tbot<N>
```

> The map updates live as you drive. Keep an eye on RViz to see which areas still need to be explored.

### Save the map

Once the map looks complete, save it with:

```bash
ros2 run nav2_map_server map_saver_cli -f ~/map
```

This produces two files in your home directory:
- `map.pgm`: the map image
- `map.yaml`: metadata (resolution, origin, thresholds)

> Do not stop the SLAM launch before saving; the map is held in memory and will be lost.

---

## 3. Navigating with the Map

### Launch the navigation stack

Stop the SLAM launch, then start the Nav2 navigation stack with the saved map:

```bash
ros2 launch turtlebot4_navigation nav2.launch.py \
    namespace:=tbot<N> \
    map:=$HOME/map.yaml
```

### Send a navigation goal from RViz

In RViz, use the **Nav2 Goal** tool (arrow icon in the toolbar) to click a destination on the map. Click once to set position, drag to set orientation. The robot will plan a path and drive there autonomously.

### Send a navigation goal programmatically

The navigation stack exposes a `NavigateToPose` action. The simplest way to use it in Python is through the `nav2_simple_commander` library:

```python
from geometry_msgs.msg import PoseStamped
from nav2_simple_commander.robot_navigator import BasicNavigator
import rclpy


def main():
    rclpy.init()
    navigator = BasicNavigator(namespace='tbot<N>')

    # Wait for Nav2 to be ready before sending any goal
    navigator.waitUntilNav2Active()

    # Build the target pose in the map frame
    goal = PoseStamped()
    goal.header.frame_id = 'map'
    goal.header.stamp = navigator.get_clock().now().to_msg()
    goal.pose.position.x = 1.0    # metres from the map origin
    goal.pose.position.y = 0.5
    goal.pose.orientation.w = 1.0  # facing forward (no rotation)

    navigator.goToPose(goal)

    # Block until the robot reaches the goal or fails
    while not navigator.isTaskComplete():
        pass

    print('Goal reached.')
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

Add `nav2_simple_commander` to your `package.xml`:

```xml
<depend>nav2_simple_commander</depend>
```

---

## 4. Mission — Navigate and Take a Photo

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

    # Publisher on the snapshot trigger topic (same namespace as the robot)
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

    # Trigger the snapshot once the robot has stopped at the goal
    trigger_pub.publish(Empty())
    navigator.get_logger().info('Goal reached; photo triggered.')

    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

> The snapshot node and the navigation node are independent and communicate only through the `take_picture` topic. You can swap out either without changing the other.

---

## 5. Exercises

**Exercise 1 — Build a map**

Launch SLAM and drive the robot until the map covers the full area. Save the map and inspect the `.pgm` and `.yaml` files. What does the resolution field in the YAML file mean?

**Exercise 2 — Navigate to a point**

Launch navigation with your saved map. Use the RViz goal tool to send the robot to three different positions. Observe the planned path: does it always take the shortest route?

**Exercise 3 — Navigate programmatically**

Write a node using `BasicNavigator` that drives the robot through a sequence of waypoints. The robot should visit each point in order and log its arrival at each one.

**Exercise 4 — Photo mission**

Extend Exercise 3 so that the robot takes a photo at each waypoint before moving on to the next.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Map stays grey after SLAM launch | SLAM is initialising; wait a few seconds, then start driving |
| Map becomes distorted while driving | Robot moving too fast; slow down to give the LIDAR time to update |
| `map_saver_cli` saves an empty map | Map not yet populated; drive around more before saving |
| Nav2 refuses to plan a path | Goal is in an obstacle or unknown space; pick a clearly white area on the map |
| `waitUntilNav2Active()` blocks indefinitely | Nav2 not fully started; wait longer or check for errors with `ros2 node list` |
| Photo not saved after mission | `camera_snapshot` node not running, or namespace mismatch on `take_picture` topic |
