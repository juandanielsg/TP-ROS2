# rqt — Graphical Debugging Tools

**What it is:** a collection of GUI plugins for inspecting and interacting with a running ROS2 system. Each tool complements the command-line tools you already know, presenting the same information in a more browsable interface.

---

## Launching rqt

All plugins can be loaded from a single window:

```bash
rqt
```

Then open a plugin from the menu: **Plugins → (category) → (tool)**.

Alternatively, each tool can be launched directly as a standalone window, as shown in each section below.

---

## rqt_graph — Node and Topic Graph

Displays the live graph of all nodes and the topics connecting them. Essential for understanding which nodes are talking to each other and spotting broken connections.

```bash
rqt_graph
```

| Button | Effect |
|--------|--------|
| Refresh | Redraw the graph with the current state |
| Nodes only | Hide topics, show only node-to-node connections |
| Nodes/Topics (all) | Show every topic, including those with no active subscriber |

> Run this whenever a node does not seem to receive messages: if the expected edge is missing from the graph, there is a namespace mismatch or a node that has not started.

---

## rqt_topic — Topic Browser

A GUI equivalent of `ros2 topic list` and `ros2 topic echo` combined. Lets you browse all active topics, see their types and rates, and expand message fields without typing the full topic name.

```bash
ros2 run rqt_topic rqt_topic
```

Check the box next to a topic to start printing its values in the table. Useful for quickly browsing what a message contains before writing a subscriber.

---

## rqt_plot — Live Data Plot

Plots numeric topic fields over time. Useful for monitoring values that change continuously: battery voltage, wheel speeds, odometry position, LIDAR ranges.

```bash
rqt_plot
```

Type a topic field path into the input box and press Enter to add it to the plot. The syntax is:

```
/tbot<N>/odom/pose/pose/position/x
/tbot<N>/battery_state/voltage
/tbot<N>/wheel_vels/velocity_left
```

Multiple fields can be plotted simultaneously on the same graph.

---

## rqt_console — Log Viewer

Displays the log output of all running nodes in one place, with filtering by severity level and node name. More convenient than reading multiple terminals when several nodes are running at once.

```bash
ros2 run rqt_console rqt_console
```

| Level | Meaning |
|-------|---------|
| DEBUG | Verbose internal information |
| INFO | Normal operation messages |
| WARN | Something unexpected but recoverable |
| ERROR | A failure that affects node behaviour |
| FATAL | Node cannot continue |

---

## rqt_image_view — Camera Viewer

Displays the image stream from any image topic. Simpler than configuring RViz when you just want to see what the camera sees.

```bash
ros2 run rqt_image_view rqt_image_view
```

Select the topic from the drop-down at the top. For the TurtleBot4 camera:

```
/tbot<N>/oakd/rgb/preview/image_raw
```

> The camera is inactive while the robot is docked; if no image appears, check the dock status first (see `docked_mode.md`).

---

## Quick Reference

| Tool | Launch command | Equivalent CLI |
|------|---------------|----------------|
| Node/topic graph | `rqt_graph` | `ros2 node list` + `ros2 topic list` |
| Topic browser | `ros2 run rqt_topic rqt_topic` | `ros2 topic echo` |
| Live data plot | `rqt_plot` | `ros2 topic echo` + manual reading |
| Log viewer | `ros2 run rqt_console rqt_console` | terminal output |
| Camera viewer | `ros2 run rqt_image_view rqt_image_view` | — |
