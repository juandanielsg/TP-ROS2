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

## Troubleshooting

| Symptom | Likely cause |
|---------|-------------|
| `ModuleNotFoundError` when importing the message | Package not built, or `install/local_setup.bash` not sourced |
| `Unknown message type` in `ros2 topic echo` | Same as above — source the workspace overlay |
| Build fails with `rosidl` error | `CMakeLists.txt` or `package.xml` missing the `rosidl_generate_interfaces` call |
| Field name collision | Field names must be `snake_case`; CamelCase names are rejected by the parser |
