# Docked Mode — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

The TurtleBot4 behaves differently depending on whether it is sitting on its charging dock or not. Understanding these differences avoids a common source of confusion during practical sessions.

---

## What Changes When Docked

| Feature | Docked | Undocked |
|---------|--------|----------|
| Battery | Charging | Discharging |
| Camera (OAK-D) | **Disabled** | Active |
| LED ring | System-controlled (charging animation) | Fully controllable |
| Motor reflexes | Suppressed | Active |
| General behaviour | Power-saving mode | Full operation |

> The camera is inactive as long as the robot is on its dock. If you do not see any image topic in RViz, check whether the robot is docked first.

---

## Checking Dock Status

The `dock_status` topic reports the current docking state:

```bash
ros2 topic echo /tbot<N>/dock_status
```

The relevant field is `is_docked`: `true` when on the dock, `false` otherwise.

---

## Docking and Undocking via ROS2

The TurtleBot4 exposes ROS2 actions to dock and undock autonomously. The robot uses its IR sensors to locate and approach the dock.

**Undock:**
```bash
ros2 action send_goal /tbot<N>/undock irobot_create_msgs/action/Undock {}
```

**Dock:**
```bash
ros2 action send_goal /tbot<N>/dock irobot_create_msgs/action/DockServo {}
```

The robot will navigate to the dock automatically. Make sure the dock is visible and unobstructed before sending the command.

---

## Powering the Robot On and Off

**On:** place the robot on its dock; it starts automatically.

**Off:** move it off the dock, then hold the central button (large circular button) for 10 seconds until the robot plays a short melody and shuts down.

---

## Practical Notes

- **Always turn off the LIDAR when the robot is docked and not in use.** The LIDAR draws significant power and will drain the battery even while charging if left running.
- **Do not run navigation or control nodes while docked.** The motor commands are suppressed, so the robot will not respond, and odometry will not update correctly.
- **Restart your nodes after undocking.** Some topics (notably the camera) only become active once the robot leaves the dock, so nodes started while docked may not receive data until restarted.
