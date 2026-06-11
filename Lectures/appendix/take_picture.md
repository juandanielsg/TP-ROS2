# Taking a Picture — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**What you will build:** a ROS2 node that captures a photo from the TurtleBot4's camera and saves it to disk whenever it receives a message on a trigger topic. It combines the subscriber pattern from Session 2 with image handling via `cv_bridge`.

---

## Prerequisites

- Session 2 completed (subscriber node)
- Robot undocked (the camera is inactive while docked; see `docked_mode.md`)
- Your robot number (replace `<N>` throughout)

---

## 1. Camera Topics

The TurtleBot4 uses an **OAK-D Lite** stereo camera. The main RGB image topic is:

```
/tbot<N>/oakd/rgb/preview/image_raw
```

To confirm it is publishing:

```bash
ros2 topic hz /tbot<N>/oakd/rgb/preview/image_raw
```

If the topic is absent or the rate is zero, check that the robot is undocked and that the camera node is running.

---

## 2. Install Dependencies

The `cv_bridge` package converts between ROS2 `Image` messages and OpenCV images:

```bash
sudo apt install ros-humble-cv-bridge python3-opencv
```

Add the dependencies to your `package.xml`:

```xml
<depend>sensor_msgs</depend>
<depend>std_msgs</depend>
<depend>cv_bridge</depend>
```

---

## 3. The Node

Create a new file `camera_snapshot.py` in your package directory (see `multiple_nodes.md` for how to register it).

```python
import cv2
from cv_bridge import CvBridge
from sensor_msgs.msg import Image
from std_msgs.msg import Empty

import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data, QoSProfile


class CameraSnapshot(Node):

    def __init__(self):
        super().__init__('camera_snapshot')

        # cv_bridge converts between ROS2 Image messages and OpenCV arrays
        self.bridge = CvBridge()

        # Hold the latest camera frame so we can save it on demand
        self.latest_frame = None

        # Subscribe to the camera; we always keep the most recent frame
        self.create_subscription(
            Image,
            'oakd/rgb/preview/image_raw',   # relative topic, namespace applied at launch
            self.image_callback,
            qos_profile_sensor_data)

        # Subscribe to the trigger topic; any message on it fires a snapshot
        # std_msgs/Empty carries no data; it is used purely as a signal
        self.create_subscription(
            Empty,
            'take_picture',                 # relative topic, namespace applied at launch
            self.trigger_callback,
            QoSProfile(depth=1))

        self.get_logger().info('Ready: publish on ~/take_picture to take a photo.')

    def image_callback(self, msg: Image):
        # Convert the ROS2 Image message to an OpenCV BGR image and cache it
        self.latest_frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')

    def trigger_callback(self, _msg: Empty):
        # The message content is ignored; receiving it is the trigger
        self.save_photo()

    def save_photo(self):
        if self.latest_frame is None:
            # No frame received yet; camera may still be starting up
            self.get_logger().warn('No image received yet, cannot save.')
            return

        # Build a timestamped filename so photos are never overwritten
        timestamp = self.get_clock().now().to_msg()
        filename = f'snapshot_{timestamp.sec}.jpg'

        cv2.imwrite(filename, self.latest_frame)
        self.get_logger().info(f'Photo saved: {filename}')


def main(args=None):
    rclpy.init(args=args)
    node = CameraSnapshot()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

### Key concepts

| Concept | What it does here |
|---------|-------------------|
| `std_msgs/msg/Empty` | A message with no fields, used as a pure signal to trigger an action |
| `CvBridge.imgmsg_to_cv2(msg, encoding)` | Converts a ROS2 `Image` message to a NumPy array that OpenCV understands |
| `desired_encoding='bgr8'` | Requests a standard 8-bit BGR image, the format OpenCV uses by default |
| `cv2.imwrite(filename, image)` | Saves the OpenCV image array to disk as a JPEG (or PNG if the extension is `.png`) |
| Caching `latest_frame` | The camera publishes continuously; we store the most recent frame so it is ready the moment the trigger arrives |

---

## 4. Build and Run

Register the node in `setup.py` (see `multiple_nodes.md`), then build:

```bash
cd ~/turtlebot4_ws
colcon build --symlink-install --packages-select turtlebot4_python_tutorials
source install/local_setup.bash
```

Run with your robot's namespace:

```bash
ros2 run turtlebot4_python_tutorials camera_snapshot --ros-args -r __ns:=/tbot<N>
```

To trigger a snapshot from another terminal:

```bash
ros2 topic pub --once /tbot<N>/take_picture std_msgs/msg/Empty {}
```

The photo is saved as `snapshot_<timestamp>.jpg` in the current working directory. Any other node in the system can trigger a snapshot by publishing to the same topic, with no code changes needed.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| `No image received yet` warning | Camera not publishing; check the robot is undocked and run `ros2 topic hz` on the image topic |
| `cv_bridge` import error | Package not installed; run `sudo apt install ros-humble-cv-bridge` |
| Saved image is black or garbled | Wrong encoding; try `desired_encoding='rgb8'` or `'mono8'` and check the topic's actual encoding with `ros2 topic echo --once` |
| Trigger has no effect | Wrong namespace; verify with `ros2 topic list \| grep take_picture` |
