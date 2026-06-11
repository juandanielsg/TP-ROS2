# OAK-D Camera Nodes Missing — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

If the `oakd` topics (e.g. `/tbot<N>/oakd/rgb/preview/image_raw`) do not appear in `ros2 topic list`, or RViz shows no image, work through the checks below **in order**. Most of the time the cause is one of the first two.

---

## 1. Is the Robot Docked?

The OAK-D camera is **disabled while the robot is on its charging dock** (see `docked_mode.md`). Check the dock status:

```bash
ros2 topic echo /tbot<N>/dock_status --once
```

If `is_docked: true`, undock the robot:

```bash
ros2 action send_goal /tbot<N>/undock irobot_create_msgs/action/Undock {}
```

Then give the camera node ~30 seconds to start and check again:

```bash
ros2 topic hz /tbot<N>/oakd/rgb/preview/image_raw
```

---

## 2. Is Your PC Seeing the Robot at All?

If the camera topics are missing but so is everything else, the problem is network discovery, not the camera. Check what your PC can see:

```bash
ros2 topic list | grep tbot<N>
ros2 node list | grep tbot<N>
```

- **Nothing at all** → your PC and the robot are not on the same network / DDS domain. Check the Wi-Fi connection and your `ROS_DOMAIN_ID`, then restart the ROS 2 daemon:

  ```bash
  ros2 daemon stop && ros2 daemon start
  ```

- **Other topics present (e.g. `/tbot<N>/battery_state`) but no `oakd` topics** → the camera node itself is down; continue below.

Expected camera nodes when everything is healthy:

```bash
ros2 node list | grep oakd
# /tbot<N>/oakd
# /tbot<N>/oakd_container
```

---

## 3. Restart the TurtleBot4 Service on the Raspberry Pi

The camera node runs on the robot's Raspberry Pi as part of the `turtlebot4` system service. If it crashed (the OAK-D pipeline occasionally fails to start), restarting the service usually fixes it.

SSH into the robot:

```bash
ssh ubuntu@<robot-ip>
```

Check the service and look for camera errors:

```bash
sudo systemctl status turtlebot4.service
journalctl -u turtlebot4.service --since "10 min ago" | grep -i -E "oak|depthai|camera"
```

Restart it:

```bash
sudo systemctl restart turtlebot4.service
```

Wait ~1 minute for everything to come back up, then re-check the topics from your PC.

---

## 4. Is the Camera Detected on USB?

Still on the Raspberry Pi, check that the OAK-D is visible as a USB device:

```bash
lsusb | grep -i -E "movidius|luxonis|03e7"
```

You should see a device with vendor ID `03e7` (Intel Movidius / Luxonis). If **nothing appears**:

1. Power off the robot.
2. Reseat the USB-C cable between the camera and the Raspberry Pi at both ends.
3. Power the robot back on and check `lsusb` again.

> The device ID changes when the camera boots its firmware — seeing `Movidius MyriadX` is normal and means the camera is alive.

---

## 5. Launch the Camera Node Manually

If the service is running but the camera nodes still do not start, launch the camera by hand on the Raspberry Pi to see the actual error message:

```bash
ros2 launch turtlebot4_bringup oakd.launch.py namespace:=/tbot<N>
```

Common errors and what they mean:

| Error message | Likely cause |
|---------------|--------------|
| `libdepthai-core.so: cannot open shared object file` | The DepthAI core library is missing → **see fix below** |
| `No available devices` | Camera not detected on USB → go back to step 4 |
| `X_LINK_DEVICE_ALREADY_IN_USE` | Another process is holding the camera (the service is still running) → stop it first: `sudo systemctl stop turtlebot4.service`, or just restart the service instead of launching manually |
| `Failed to find device after booting` | Flaky USB connection or under-voltage → reseat the cable, check the battery is charged |
| Node starts, then dies after a few seconds | Power-cycle the whole robot (full shutdown, not just service restart) |

### Fix: `libdepthai-core.so` not found

`depthai_ros_driver` loaded successfully but `libdepthai-core.so` is missing. This happens when `ros-humble-depthai` is marked as installed by dpkg but the shared library file was never extracted or was accidentally deleted — confirmed by `dpkg -l ros-humble-depthai` showing `ii` while `dpkg -S libdepthai-core.so` returns nothing.

Reinstall the package to restore the missing file:

```bash
sudo apt install --reinstall ros-humble-depthai
sudo ldconfig
sudo systemctl restart turtlebot4.service
```

Give it ~1 minute and verify from your PC:

```bash
ros2 node list | grep oakd
ros2 topic hz /tbot<N>/oakd/rgb/preview/image_raw
```

---

## 6. Last Resort: Full Power Cycle

The OAK-D firmware can get into a state that only a cold boot clears:

1. Place the robot **off** the dock.
2. Shut it down cleanly (hold the power button, or `sudo shutdown now` on the Pi).
3. Wait ~10 seconds, power it back on.
4. Wait for the full startup (LED ring stable, ~2 minutes), then check:

```bash
ros2 topic hz /tbot<N>/oakd/rgb/preview/image_raw
```

---

## Quick Reference

| Check | Command (from your PC unless noted) |
|-------|--------------------------------------|
| Docked? | `ros2 topic echo /tbot<N>/dock_status --once` |
| Robot visible? | `ros2 topic list \| grep tbot<N>` |
| Camera publishing? | `ros2 topic hz /tbot<N>/oakd/rgb/preview/image_raw` |
| Camera nodes up? | `ros2 node list \| grep oakd` |
| Service status | *(on the Pi)* `sudo systemctl status turtlebot4.service` |
| Restart service | *(on the Pi)* `sudo systemctl restart turtlebot4.service` |
| USB detection | *(on the Pi)* `lsusb \| grep -i -E "movidius\|luxonis\|03e7"` |
