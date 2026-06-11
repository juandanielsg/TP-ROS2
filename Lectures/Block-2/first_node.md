# First Python Node — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**What you will build:** a ROS2 node that listens to the TurtleBot's physical buttons and controls the LED ring in response. It demonstrates the two most fundamental ROS2 patterns: **subscribing** to a topic and **publishing** to a topic.

---

## Prerequisites

- ROS2 Humble installed and sourced
- A TurtleBot4 reachable on the network (or running in simulation)
- Basic Python knowledge

---

## 1. Create the Workspace

If you don't have a workspace yet:

```bash
mkdir -p ~/turtlebot4_ws/src
```

> This creates the directory layout. The workspace is not usable until it has been built at least once; we will do that in [Section 5](#5-build).

---

## 2. Create the Package

```bash
source /opt/ros/humble/setup.bash
cd ~/turtlebot4_ws/src
ros2 pkg create --build-type ament_python \
    --node-name turtlebot4_first_python_node \
    turtlebot4_python_tutorials
```

This generates the following structure:

```
turtlebot4_python_tutorials/
├── package.xml
├── setup.cfg
├── setup.py
└── turtlebot4_python_tutorials/
    └── turtlebot4_first_python_node.py   ← your node
```

---

## 3. Declare Dependencies

Open `package.xml` and add the two dependencies your node needs:

```xml
<depend>rclpy</depend>
<depend>irobot_create_msgs</depend>
```

- `rclpy` is the ROS2 Python client library.
- `irobot_create_msgs` provides the message types for the Create3 base (buttons, LED ring, etc.).

---

## 4. Write the Node

Replace the contents of `turtlebot4_first_python_node.py` with the following.

> **Namespace note:** the topic names below are *relative* (no leading `/`). This means they automatically adapt to whatever namespace you pass at launch time, which is useful in a lab with multiple robots. See [Section 6](#6-run-the-node) for how to set the namespace.

```python
from irobot_create_msgs.msg import InterfaceButtons, LightringLeds

import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data


class TurtleBot4FirstNode(Node):
    lights_on_ = False

    def __init__(self):
        super().__init__('turtlebot4_first_python_node')

        # Subscribe to button events from the Create3 base
        self.interface_buttons_subscriber = self.create_subscription(
            InterfaceButtons,
            'interface_buttons',          # relative topic (namespace is applied at launch)
            self.interface_buttons_callback,
            qos_profile_sensor_data)

        # Publisher to control the LED ring
        self.lightring_publisher = self.create_publisher(
            LightringLeds,
            'cmd_lightring',              # relative topic
            qos_profile_sensor_data)

    def interface_buttons_callback(self, create3_buttons_msg: InterfaceButtons):
        if create3_buttons_msg.button_1.is_pressed:
            self.get_logger().info('Button 1 Pressed!')
            self.button_1_function()

    def button_1_function(self):
        lightring_msg = LightringLeds()
        lightring_msg.header.stamp = self.get_clock().now().to_msg()

        if not self.lights_on_:
            lightring_msg.override_system = True   # take control from the system

            # Set colors for each of the 6 LEDs (RGB values 0–255)
            lightring_msg.leds[0].red = 255; lightring_msg.leds[0].blue = 0;   lightring_msg.leds[0].green = 0
            lightring_msg.leds[1].red = 0;   lightring_msg.leds[1].blue = 255; lightring_msg.leds[1].green = 0
            lightring_msg.leds[2].red = 0;   lightring_msg.leds[2].blue = 0;   lightring_msg.leds[2].green = 255
            lightring_msg.leds[3].red = 255; lightring_msg.leds[3].blue = 255; lightring_msg.leds[3].green = 0
            lightring_msg.leds[4].red = 255; lightring_msg.leds[4].blue = 0;   lightring_msg.leds[4].green = 255
            lightring_msg.leds[5].red = 0;   lightring_msg.leds[5].blue = 255; lightring_msg.leds[5].green = 255
        else:
            lightring_msg.override_system = False  # give control back to the system

        self.lightring_publisher.publish(lightring_msg)
        self.lights_on_ = not self.lights_on_


def main(args=None):
    rclpy.init(args=args)
    node = TurtleBot4FirstNode()
    rclpy.spin(node)          # blocks until Ctrl+C
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

### Key concepts

| Concept | What it does here |
|---------|-------------------|
| `create_subscription(MsgType, topic, callback, qos)` | Registers a function to be called every time a message arrives on `topic` |
| `create_publisher(MsgType, topic, qos)` | Creates an outgoing channel on `topic` |
| `qos_profile_sensor_data` | A QoS preset suited for sensor streams (best-effort, keep last 10) |
| `rclpy.spin(node)` | Keeps the node alive and processes incoming messages in a loop |
| `override_system = True/False` | Tells the Create3 whether your node or the robot firmware owns the LED ring |

---

## 5. Build

```bash
cd ~/turtlebot4_ws
colcon build --symlink-install --packages-select turtlebot4_python_tutorials
source install/local_setup.bash
```

`--symlink-install` means you don't need to rebuild after editing Python files.

---

## 6. Run the Node

### Without namespace (single robot or simulation)

```bash
ros2 run turtlebot4_python_tutorials turtlebot4_first_python_node
```

The node will subscribe to `interface_buttons` and publish to `cmd_lightring`.

### With a namespace (multiple robots in the lab)

Pass the robot's namespace so topics are correctly routed to *your* robot:

```bash
ros2 run turtlebot4_python_tutorials turtlebot4_first_python_node \
    --ros-args -r __ns:=/turtlebot1
```

The node will then subscribe to `/turtlebot1/interface_buttons` and publish to `/turtlebot1/cmd_lightring`, without any change to the source code.

Replace `turtlebot1` with the namespace of whichever robot you are working with.

---

## 7. Test It

1. Press **Button 1** (the one labeled `1` on the top of the robot).
2. The LED ring should light up with 6 different colors.
3. Press it again; the LEDs should turn off and return to system control.

You should also see log output in the terminal:

```
[INFO] [turtlebot4_first_python_node]: Button 1 Pressed!
```

---

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| No messages received | Wrong namespace; check with `ros2 topic list` |
| `irobot_create_msgs` not found | Run `sudo apt install ros-humble-irobot-create-msgs` |
| LEDs don't change | The TurtleBot may be docked (power-saving mode suppresses LED override) |
| `qos_profile_sensor_data` mismatch warning | Publisher and subscriber QoS profiles must match; use `qos_profile_sensor_data` on both sides |
