# ROS Architecture — Communication Patterns

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**What this session covers:** the three communication primitives ROS2 provides — topics, services, and actions. Understanding when to reach for each one is the foundation of every ROS2 system you will build.

---

## 1. Publishers and Subscribers

The **pub/sub** pattern is the most common way nodes exchange data in ROS2. A publisher sends messages onto a named topic; any number of subscribers receive them independently.

```
[ sensor node ]
      │  publishes /scan
      ▼
  [ /scan topic ]
      ├──▶ [ mapping node ]
      ├──▶ [ obstacle avoidance node ]
      └──▶ [ logger node ]
```

The publisher does not know who is listening, or whether anyone is. Subscribers do not know where the data comes from. Both sides agree only on the **topic name** and **message type**. Communication is **asynchronous**: the publisher sends and moves on; the subscriber is called back whenever a message arrives.

### Key properties

| Property | Value |
|----------|-------|
| Direction | One-to-many (fan-out) |
| Timing | Asynchronous |
| Coupling | Anonymous — neither side knows the other |
| Best for | Continuous data streams (sensors, state estimates, images) |

### Inspecting topics from the terminal

```bash
ros2 topic list                        # all active topics
ros2 topic echo /tbot<N>/scan          # print messages as they arrive
ros2 topic info /tbot<N>/scan          # message type and connection count
ros2 topic hz   /tbot<N>/scan          # publishing frequency
ros2 topic bw   /tbot<N>/scan          # bandwidth in bytes/s
```

### QoS

Every publisher and subscriber declares a **Quality of Service** profile. The most important settings are:

| Setting | Options | Effect |
|---------|---------|--------|
| Reliability | `RELIABLE` / `BEST_EFFORT` | Whether dropped messages are retransmitted |
| Durability | `VOLATILE` / `TRANSIENT_LOCAL` | Whether late subscribers receive the last cached message |
| History | `KEEP_LAST(N)` / `KEEP_ALL` | How many messages are buffered |

Sensor data typically uses `BEST_EFFORT` (speed over guarantee). Configuration or status data uses `RELIABLE` + `TRANSIENT_LOCAL` so a node that starts late still receives the latest value.

> Mismatched QoS is a common source of silent failures: the connection appears in `ros2 topic info` but no messages are ever delivered.

---

## 2. Services

A **service** is a synchronous request-reply interaction. The client sends a **request** and blocks until the server returns a **response**. Unlike a topic there is no continuous stream — it is a single, atomic exchange.

```
[ client node ] ──── request ────▶ [ server node ]
                ◀─── response ───
```

### Key properties

| Property | Value |
|----------|-------|
| Direction | One client to one server |
| Timing | Synchronous — client blocks until reply |
| Best for | Configuration, one-time commands, state queries |

### When to use a service instead of a topic

Use a service when:
- The caller needs a guaranteed reply before proceeding.
- The operation is a command or query, not a data stream.
- The interaction happens occasionally, not continuously.

### Inspecting services from the terminal

```bash
ros2 service list                                            # all active services
ros2 service type /tbot<N>/e_stop                           # service type
ros2 interface show irobot_create_msgs/srv/EStop            # request/response definition
ros2 service call /tbot<N>/e_stop \
    irobot_create_msgs/srv/EStop "{e_stop_on: true}"        # call it directly
```

### TurtleBot4 examples

| Service | What it does |
|---------|-------------|
| `/tbot<N>/e_stop` | Engage or release the emergency stop |
| `/tbot<N>/robot_power` | Power off the Create3 base |
| `/tbot<N>/motion_control` | Enable or disable motor control |

> Do not use a service for operations that take more than a fraction of a second. The calling node is frozen for the entire duration. For anything longer, use an action (Section 3).

---

## 3. Action Servers

An **action** is designed for long-running tasks where the client wants periodic **feedback** during execution and the ability to **cancel** mid-way. The result is only meaningful once the task finishes.

```
[ client ]
   │  sends Goal
   ▼
[ action server ]                 [ client ]
   │                                  ▲
   ├── Feedback (repeated) ───────────┤
   │                                  │
   └── Result (once, on completion) ──┘
```

Every action has exactly three parts:

| Part | When it is sent | Contents |
|------|----------------|----------|
| **Goal** | Once, by the client | What to do |
| **Feedback** | Repeatedly, by the server | Progress updates |
| **Result** | Once, by the server | Final outcome (success or failure) |

### Key properties

| Property | Value |
|----------|-------|
| Direction | One client to one server |
| Timing | Asynchronous with streaming feedback |
| Cancellable | Yes — client can cancel at any time |
| Best for | Navigation, any multi-step task with visible progress |

### Inspecting actions from the terminal

```bash
ros2 action list                            # all active action servers
ros2 action info /tbot<N>/dock              # goal, feedback, and result types
ros2 action send_goal \
    /tbot<N>/dock \
    irobot_create_msgs/action/Dock "{}"     # send a goal and wait for result
```

To also print feedback messages as the server works:

```bash
ros2 action send_goal --feedback \
    /tbot<N>/dock \
    irobot_create_msgs/action/Dock "{}"
```

### TurtleBot4 examples

| Action | Goal | Feedback | Result |
|--------|------|----------|--------|
| `/tbot<N>/dock` | (none) | `is_docked` | `is_docked` |
| `/tbot<N>/undock` | (none) | (none) | `is_docked` |
| `/tbot<N>/wall_follow` | `follow_side`, `max_runtime` | `pose` | `runtime_elapsed` |
| `/tbot<N>/navigate_to_pose` | target `pose` | `current_pose`, `distance_remaining` | `result` |

---

## 4. Choosing the Right Pattern

| Situation | Use |
|-----------|-----|
| Continuous data stream (sensor, estimate, image) | Topic |
| Turn a feature on or off | Service |
| Query a single value and act on the reply | Service |
| Move to a position | Action |
| Any task that takes longer than ~100 ms | Action |
| Any task the user might want to cancel | Action |

A common mistake is wrapping a long-running task in a service. The client process freezes for the entire duration and cannot react to anything else. If the task takes more than a fraction of a second, the answer is always an action.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|-------------|
| Subscriber receives nothing despite publisher running | QoS mismatch; check reliability and durability settings on both sides |
| Service call hangs indefinitely | Server node is not running, or it is stuck on a long computation |
| Action goal is rejected immediately | Goal validation failed; check field names with `ros2 interface show` |
| `ros2 action list` shows nothing | Action server not yet started; the node may still be initialising |
| `ros2 service call` returns an unknown type error | Package not installed or ROS2 not sourced |
