# Evaluation Cheatsheet — Session 6

The final session is a **15-minute presentation** that walks through your work over the course. This document helps you prepare it.

---

## Format

- 15 minutes per group, followed by a few questions
- Slideshow format (any tool: PowerPoint, Google Slides, LibreOffice Impress)
- Include photos and videos taken during the sessions — they are the main evidence of your work

---

## Suggested Structure

### 1. What is ROS?
A brief, non-technical introduction for someone who has never heard of ROS:
- What problem does it solve?
- Key concepts: nodes, topics, messages
- Why it is useful for robotics

### 2. The TurtleBot4
- What hardware it consists of (Raspberry Pi, Create3, LIDAR, OAK-D camera)
- How it connects to the network and to your PC

### 3. Session walkthrough
Go through each session in order and show what you achieved. Keep it factual: what was the goal, what did you run or build, and what did you observe. Use screenshots, terminal output, and videos.

| Session | Key things to show |
|---------|-------------------|
| 2 | RViz running, topic list output, battery monitoring node output |
| 3 | Robot moving via keyboard and joystick, RViz with odom frame |
| 4 | Odometry output in terminal, robot reaching a target point |
| 5 | SLAM map building in progress, robot navigating autonomously, photo taken at destination |

### 4. Conclusion
- Insights.

---

## Checklist — Collect These During the Sessions

Go through this list as you work and make sure you have evidence for each item before Session 6.

**Session 2**
- [ ] Screenshot of `ros2 topic list` output
- [ ] Screenshot or video of RViz launching with the robot model
- [ ] Terminal output of `ros2 topic echo /tbot<N>/battery_state`
- [ ] Terminal output of your battery monitoring node running

**Session 3**
- [ ] Video of keyboard teleoperation
- [ ] Video of joystick control
- [ ] Screenshot of RViz with the laser scan displayed and Fixed Frame = `odom`

**Session 4**
- [ ] Terminal output of your odometry reader node
- [ ] Video of the robot driving to a target point

**Session 5**
- [ ] Screenshot or video of the SLAM map building in real time
- [ ] The saved `map.pgm` file (open it and take a screenshot)
- [ ] Video of autonomous navigation to a goal
- [ ] Photo taken by the robot at the end of the mission

---

## Tips

- **Start the slideshow early** — do not wait until Session 6 to open a presentation file. Add one slide per session as you go.
- **Narrate, do not read** — the slides support what you say; they should not contain every sentence you plan to speak.
- **Explain your reasoning** — the presentation values understanding over completion. A well-explained partial result is better than a complete result you cannot explain.
- **Show failures too** — if something did not work, explain what you tried and what you think went wrong. This demonstrates understanding.
