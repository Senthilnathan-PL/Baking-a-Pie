# Docker for Robotics — Complete Guide

### From Zero to Running ROS2 on a Raspberry Pi AMR

---

## Who this is for

You are building an Autonomous Mobile Robot (AMR). Your Pi runs ROS2. Your ESP32 talks to the Pi over UART. You want everything packaged cleanly so it runs the same way every single time, on any machine. Docker is the tool that makes that possible.

This guide takes you from "what even is Docker" all the way to running your robot's software in a container with full access to GPIO, UART, I2C, and the network.

---

# Part 1 — Understanding Docker

## What problem does Docker solve?

Imagine you build your robot software on your laptop. Everything works perfectly. You copy it to the Pi and suddenly nothing works — wrong Python version, missing libraries, different Ubuntu version. This is the classic "it works on my machine" problem.

Docker solves this by packaging your software together with everything it needs to run — the operating system files, the libraries, the environment variables, all of it — into one neat box called a **container**. That container runs identically on your laptop, on the Pi, on any machine.

---

## The three core concepts

Before touching any command, you need these three ideas locked in your head.

### Image — the blueprint

A Docker image is a frozen, read-only snapshot of a complete system. Think of it like a photograph of a perfectly configured computer. It contains the operating system files, all installed software, your code, and all settings. Nothing can change inside an image — it is frozen.

You build an image once from a Dockerfile. You can share it, copy it, archive it. It never changes.

### Container — the running instance

A container is what you get when you take an image and actually run it. Think of the image as a blueprint for a room, and the container as the actual room that gets built from that blueprint. You can build many rooms from the same blueprint. Each room is separate — what happens in one does not affect the others.

A container runs one main program. When that program stops, the container stops. When you delete the container, it is gone — but the image it came from still exists, ready to create a new container.

### Dockerfile — the recipe

A Dockerfile is a plain text file containing step-by-step instructions for building an image. It says things like "start from Ubuntu 22.04, install these packages, copy this file, set this environment variable." Docker reads it top to bottom and produces an image.

```
Dockerfile  →  docker build  →  Image  →  docker run  →  Container
(recipe)        (cooking)       (frozen meal)  (reheating)  (hot meal on table)
```

---

## What is Docker Hub?

Docker Hub (`hub.docker.com`) is the internet's library of pre-built Docker images. Instead of starting from a completely bare system and installing everything yourself, you start from an image someone already prepared.

When your Dockerfile says:

```dockerfile
FROM ros:humble-ros-base
```

Docker goes to Docker Hub, finds the official ROS2 Humble image, and downloads it. That image already has Ubuntu 22.04 and ROS2 installed inside. You build on top of it rather than starting from scratch.

If Docker cannot find an image locally on your machine, it automatically pulls it from Docker Hub. This is why the first `docker build` takes longer — it is downloading the base image.

---

## Installing Docker on Raspberry Pi (Debian ARM64)

The Pi runs a 64-bit ARM processor. The official Docker installation script handles this automatically.

**Step 1 — Remove any old Docker versions:**

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

**Step 2 — Download and run the official install script:**

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

**Step 3 — Allow your user to run Docker without sudo:**

```bash
sudo usermod -aG docker $USER
```

**Step 4 — Log out and log back in**, then verify:

```bash
docker run hello-world
```

You will see Docker pull the `hello-world` image from Docker Hub (because it does not exist locally yet), run it, print a success message, and exit. That is your first container.

---

## What happened during `docker run hello-world`?

This single command did several things automatically:

1. Docker looked for the `hello-world` image on your machine — not found
2. Docker went to Docker Hub and pulled (downloaded) the image
3. Docker created a new container from that image
4. The container ran its one program (which prints the hello message)
5. The program finished, so the container stopped and exited

Every time you run an image that does not exist locally, Docker pulls it first. After that first pull, it is cached locally and future runs are instant.

---

# Part 2 — Writing a Dockerfile

## How a Dockerfile is structured

Every line in a Dockerfile is an instruction. Docker executes them top to bottom during `docker build`. Each instruction that changes the filesystem creates a **layer** — a frozen snapshot of what changed. All layers stack on top of each other to form the final image.

```
Base image layer        (FROM ros:humble-ros-base)
    +
Packages layer          (RUN apt-get install ...)
    +
Environment layer       (ENV ROS_DOMAIN_ID=2)
    +
Workspace layer         (RUN colcon build)
    +
Entrypoint layer        (COPY entrypoint.sh)
    =
Your final image
```

---

## FROM — choosing your starting point

```dockerfile
FROM ros:humble-ros-base
```

This is always the first line. It tells Docker which image to start building on top of. `ros:humble-ros-base` is the official ROS2 Humble image — it already has Ubuntu 22.04 and all core ROS2 tools installed inside.

`ros-base` is preferable to plain `ros:humble` because it is lighter — it contains everything you need for running nodes without the desktop GUI tools, which you do not need on a headless Pi.

---

## ENV — permanent environment variables

```dockerfile
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ROS_DOMAIN_ID=2
```

`ENV` bakes variables into the image. Every container started from this image will have these variables set automatically, without you having to do anything.

**Why LANG and LC_ALL?** Without these, ROS2 occasionally throws character encoding errors — Python warnings, nodes that fail silently, garbled terminal output. Setting them to `C.UTF-8` prevents all of that.

**Why ROS_DOMAIN_ID?** ROS2 uses a number called Domain ID to decide which robots can talk to each other. Two machines with the same Domain ID can see each other's topics and services. Two machines with different Domain IDs are invisible to each other. Setting it here ensures every container you run has the correct ID automatically.

**Important difference — ENV vs RUN export:**

```dockerfile
ENV ROS_DOMAIN_ID=2          # ✓ Permanent — persists in every container run
RUN export ROS_DOMAIN_ID=2   # ✗ Temporary — dies when that RUN shell exits
```

`RUN export` sets a variable only inside the temporary shell that runs during `docker build`. Once that RUN step finishes, the shell dies and the variable vanishes. `ENV` is the correct way.

---

## RUN — executing commands during build

```dockerfile
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-colcon-common-extensions \
    python3-pip \
    git \
    nano \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-serial-driver \
    python3-serial \
    && rm -rf /var/lib/apt/lists/*
```

`RUN` executes a shell command during `docker build`. The result is frozen into a layer. The shell that ran the command then disappears — it does not exist at runtime.

**Key rules for RUN:**

You cannot use `sudo` inside a Dockerfile. Docker already runs as root during build. `sudo` is not installed and is not needed.

Always combine `apt-get update` and `apt-get install` in the same `RUN` command. If you split them across two RUN lines, Docker might cache the `update` step and skip it on future builds, leading to stale package lists and failed installs.

Always clean up the package cache at the end with `rm -rf /var/lib/apt/lists/*`. This removes the package index files that `apt-get update` downloaded — they are only needed during install and removing them keeps your image smaller.

**RUN only runs at build time — never at runtime.** This means you cannot `RUN source /opt/ros/humble/setup.bash` and expect ROS to be available when the container starts. The shell that sourced ROS during build is long dead by then. Sourcing at runtime is handled by the entrypoint.

---

## WORKDIR — setting the working directory

```dockerfile
WORKDIR /ros2_ws
```

Sets the default directory inside the container. Any subsequent RUN commands, and the shell you get when you `docker exec` into the container, will start in this directory.

---

## COPY — bringing files into the image

```dockerfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
```

`COPY` takes a file from your host machine (the machine running `docker build`) and places it inside the image. Here we copy the entrypoint script and then make it executable. Without `chmod +x`, Docker cannot run it.

---

## ENTRYPOINT and CMD — what runs when the container starts

These two are the most important instructions to understand, and also the most commonly confused.

### ENTRYPOINT — the always-runs command

```dockerfile
ENTRYPOINT ["/entrypoint.sh"]
```

`ENTRYPOINT` defines the command that runs every single time a container starts, no matter what. It is the container's main program launcher. You cannot skip it.

### CMD — the default argument

```dockerfile
CMD ["bash"]
```

`CMD` provides the default argument passed to `ENTRYPOINT`. If you do not provide a command when running the container, `CMD` is used. If you do provide a command, `CMD` is replaced by what you typed.

### How they combine

Docker joins them together:

```
docker run amr_ros              →  /entrypoint.sh bash
docker run amr_ros ros2 topic list  →  /entrypoint.sh ros2 topic list
```

Whatever you type after the image name replaces `CMD` and gets passed to `ENTRYPOINT` as arguments. `ENTRYPOINT` always runs first.

---

## Why entrypoint.sh is smarter than inline ENTRYPOINT

You could write the whole startup command directly in the Dockerfile:

```dockerfile
# Inline approach — gets messy fast
ENTRYPOINT ["/bin/bash", "-c", "source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash && exec \"$@\"", "--"]
```

This works but becomes hard to read and maintain as your project grows. A separate `entrypoint.sh` file is cleaner:

```bash
#!/bin/bash
set -e

source /opt/ros/humble/setup.bash
source /ros2_ws/install/setup.bash

exec "$@"
```

**Why this is better:**

Adding more setup steps later (configuring middleware, setting log directories, checking hardware) is just adding lines to a shell script — readable, testable, maintainable. The Dockerfile stays clean and just points to the script.

**What each line does:**

`#!/bin/bash` — tells the OS this file is a bash script.

`set -e` — means "exit immediately if any command fails." If `source /opt/ros/humble/setup.bash` fails because the path is wrong, the script stops right there and the container exits with an error. Without `set -e`, the script would keep going and your ROS node would start on a broken environment, giving you confusing errors with no obvious cause.

`source /opt/ros/humble/setup.bash` — loads the core ROS2 environment. This sets up all the paths and library locations ROS2 needs. Without it, `ros2` commands do not exist in the shell.

`source /ros2_ws/install/setup.bash` — loads your workspace. Once you add your own ROS2 packages and build them with `colcon build`, this line makes those packages available.

`exec "$@"` — runs whatever command was passed to the script, replacing the shell itself. This is the most important line.

---

## Understanding exec and $@

`$@` means "all the arguments given to this script." If you run:

```bash
docker run amr_ros ros2 topic list
```

Then inside `entrypoint.sh`, `$@` equals `ros2 topic list`.

The line `exec "$@"` therefore becomes `exec ros2 topic list`.

**What exec actually does** is the key concept. Normally when a shell script runs a command, the shell stays alive as a parent process and the command runs as its child:

```
Without exec:
  PID 1 → bash (entrypoint.sh)
              └── ros2 topic list   (child)
```

With `exec`, the shell does not spawn a child. It completely replaces itself with the new program:

```
With exec:
  PID 1 → ros2 topic list   (bash is gone — ros2 took its place)
```

---

## Why PID 1 matters so much

PID stands for Process ID — the number the Linux kernel assigns to every running program. PID 1 is special: it is the first process started in any Linux environment, and it is the one the kernel sends control signals to.

In Docker, the first process started in a container gets PID 1. The container lives exactly as long as PID 1 lives. When PID 1 exits, the container exits.

When you run `docker stop`, Docker sends a signal called `SIGTERM` to PID 1, asking it to shut down gracefully. If PID 1 is bash and your actual program (ros2) is a child of bash, bash may absorb the signal without passing it to ros2. Your ros2 node keeps running, Docker waits, then forcefully kills everything after a timeout. For a robot, this is dangerous — motors could stay active, the navigation stack might not save its state.

With `exec "$@"`, your ros2 process becomes PID 1 directly. `docker stop` reaches it immediately. It shuts down cleanly. Your robot is safe.

```
Without exec:  docker stop → SIGTERM → bash → (maybe) ros2   ✗ unreliable
With exec:     docker stop → SIGTERM → ros2 directly          ✓ clean shutdown
```

---

## The complete Dockerfile

```dockerfile
FROM ros:humble-ros-base

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ROS_DOMAIN_ID=2

RUN apt-get update && apt-get install -y \
    build-essential \
    python3-colcon-common-extensions \
    python3-pip \
    git \
    nano \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-serial-driver \
    python3-serial \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /ros2_ws/src
WORKDIR /ros2_ws

RUN /bin/bash -c "source /opt/ros/humble/setup.bash && colcon build"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
```

## The complete entrypoint.sh

```bash
#!/bin/bash
set -e

source /opt/ros/humble/setup.bash
source /ros2_ws/install/setup.bash

exec "$@"
```

---

## Building the image

Navigate to the folder containing your Dockerfile and entrypoint.sh:

```bash
cd amr_docker/
docker build -t amr_ros .
```

`-t amr_ros` gives the image a name (tag). The `.` tells Docker to look for the Dockerfile in the current folder.

Docker will print each step as it executes. The package install step takes the longest — Nav2 is large. First build on a Pi can take 15–30 minutes. Subsequent builds use cached layers and are much faster, rebuilding only from the line that changed.

To verify the image was created:

```bash
docker images
```

---

# Part 3 — Running Containers and Accessing Hardware

## Basic container run

```bash
docker run -it amr_ros
```

`-i` keeps stdin open so you can type. `-t` allocates a terminal (TTY) so the output looks like a normal shell. Without both flags, bash opens and immediately exits because it sees no terminal attached.

This drops you into a bash shell inside the container with ROS2 fully sourced and ready.

---

## Named containers

```bash
docker run -it --name Dragon_booster amr_ros
```

`--name` gives the container a memorable name instead of Docker's randomly generated names. Named containers are easier to work with:

```bash
docker stop Dragon_booster      # stop it
docker start Dragon_booster     # start it again
docker exec -it Dragon_booster bash   # get a shell inside it
```

---

## Interactive vs non-interactive

**Interactive** — you want a shell to poke around, debug, or manually run commands:

```bash
docker run -it --name Dragon_booster amr_ros
# Gives you a bash prompt inside the container
```

**Non-interactive** — you want to run a specific command and see its output, then exit:

```bash
docker run --rm amr_ros ros2 topic list
# Runs the command, prints output, container exits and is deleted
```

`--rm` automatically removes the container after it exits. Useful for one-off commands so you do not accumulate stopped containers.

**Running a background service** — your robot's navigation stack running silently:

```bash
docker run -d --name nav_stack amr_ros ros2 launch nav2_bringup bringup_launch.py
# -d means detached — runs in background
```

Then check its output:

```bash
docker logs nav_stack
docker logs -f nav_stack    # -f follows the log in real time
```

---

## Getting back into a running container

`docker exec` lets you run an additional command inside a container that is already running:

```bash
docker exec -it Dragon_booster bash
```

Important: `docker exec` only works on **running** containers. If the container has stopped, start it first:

```bash
docker start Dragon_booster
docker exec -it Dragon_booster bash
```

---

## Connecting to the host network

```bash
docker run -it --net=host amr_ros
```

By default, Docker gives each container its own isolated network. For ROS2, this is a problem — your container's ROS2 nodes cannot see the ROS2 nodes running on your laptop or on other devices on the network.

`--net=host` removes this isolation and makes the container share the Pi's network directly. The container's network IS the Pi's network. ROS2 DDS discovery works normally, and topics are visible across your whole robot system.

For robotics, `--net=host` is almost always what you want.

---

## Giving containers access to hardware

This is where Docker connects to the physical world. Hardware devices on Linux appear as files under `/dev/`. To let a container use a device, you pass that device file into it.

### UART / Serial port (ESP32 communication)

```bash
docker run -it --net=host \
    --device=/dev/ttyAMA0 \
    amr_ros
```

`/dev/ttyAMA0` is the Pi's primary UART port — the one connected to your ESP32. `--device` passes it into the container. Your Python serial node inside the container can then open `/dev/ttyAMA0` and read/write to the ESP32 exactly as it would outside Docker.

### GPIO pins

```bash
docker run -it --net=host \
    --device=/dev/gpiomem \
    amr_ros
```

`/dev/gpiomem` is the Pi's GPIO memory interface. Libraries like `RPi.GPIO` and `gpiozero` use this file to control pins.

### I2C (sensors, IMU, displays)

```bash
docker run -it --net=host \
    --device=/dev/i2c-1 \
    amr_ros
```

I2C bus 1 (`/dev/i2c-1`) is the standard I2C bus on the Pi's GPIO header (pins 3 and 5). If you have multiple I2C devices, they all share this one bus.

### SPI (high-speed sensors, some displays)

```bash
docker run -it --net=host \
    --device=/dev/spidev0.0 \
    amr_ros
```

### Multiple devices together

You can stack multiple `--device` flags:

```bash
docker run -it --net=host \
    --device=/dev/ttyAMA0 \
    --device=/dev/gpiomem \
    --device=/dev/i2c-1 \
    amr_ros
```

### Privileged mode

```bash
docker run -it --net=host \
    --privileged \
    amr_ros
```

`--privileged` gives the container access to all host devices — every `/dev/` entry on the Pi — without you having to list them individually. It also removes most other Linux security restrictions on the container.

Use `--privileged` during development when you are still figuring out which devices you need. Use specific `--device` flags in production for a tighter, safer setup.

---

## Checking what devices exist on your Pi

Before writing your run command, see what is actually available:

```bash
ls /dev/tty*      # serial ports — look for ttyAMA0, ttyUSB0
ls /dev/gpio*     # GPIO
ls /dev/i2c*      # I2C buses
ls /dev/spi*      # SPI devices
```

---

## Your complete robot run command

For your AMR with ROS2, Nav2, and ESP32 over UART:

```bash
docker run -it \
    --name Dragon_booster \
    --net=host \
    --device=/dev/ttyAMA0 \
    --device=/dev/gpiomem \
    amr_ros
```

Or during active development, simpler:

```bash
docker run -it \
    --name Dragon_booster \
    --net=host \
    --privileged \
    amr_ros
```

---

## Quick reference — essential Docker commands

```bash
# Build
docker build -t amr_ros .                    # build image from Dockerfile
docker build --no-cache -t amr_ros .         # force full rebuild, ignore cache

# Images
docker images                                # list all local images
docker rmi amr_ros                           # delete an image

# Run
docker run -it amr_ros                       # interactive shell
docker run -it --name mybot amr_ros          # named container
docker run --rm amr_ros ros2 topic list      # run command, auto-delete container
docker run -d --name mybot amr_ros           # run in background (detached)

# Container management
docker ps                                    # show running containers
docker ps -a                                 # show all containers including stopped
docker start mybot                           # start a stopped container
docker stop mybot                            # stop a running container
docker exec -it mybot bash                   # shell into running container
docker rm mybot                              # delete a stopped container

# Logs
docker logs mybot                            # show container output
docker logs -f mybot                         # follow live output
```

---

## How it all fits together — your AMR system

```
Your Laptop                    Raspberry Pi
─────────────────              ─────────────────────────────────
ros2 topic echo /cmd_vel  ←──  Docker Container (amr_ros)
                               │  ENTRYPOINT: entrypoint.sh
                               │    source ROS2
                               │    source workspace
                               │    exec ros2 launch nav2...
                               │
                               │  PID 1: ros2 launch nav2_bringup
                               │     ├── nav2 nodes
                               │     ├── serial_node → /dev/ttyAMA0
                               │     └── localization node
                               │
                     ──────────┘
                     --net=host (ROS2 visible across network)
                     --device=/dev/ttyAMA0
                               │
                               ↓ UART
                          ESP32
                    (motor control, encoders)
```

Both your laptop's ROS2 and the Pi's ROS2 container share `ROS_DOMAIN_ID=2`, so topics flow freely between them over the network — no special configuration needed.

---

*Built from real debugging sessions — Dockerfile errors, exec mechanics, PID 1 signals, and hardware passthrough — all working toward a running AMR.*