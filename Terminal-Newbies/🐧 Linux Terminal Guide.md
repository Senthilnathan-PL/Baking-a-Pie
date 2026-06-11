# 🐧 Linux Terminal Guide

### From Zero to Robotics — A Beginner's Handbook

> *"The terminal is not scary. It's just a conversation with your computer."*

------

## 📋 Table of Contents

1. [Why the Terminal?](#why-the-terminal)
2. [Navigating the File System](#navigating-the-file-system)
3. [Working with Files & Directories](#working-with-files--directories)
4. [Viewing & Editing Files](#viewing--editing-files)
5. [Permissions & Ownership](#permissions--ownership)
6. [Package Management (apt)](#package-management-apt)
7. [Process Management](#process-management)
8. [Networking Basics](#networking-basics)
9. [Shell Tips & Tricks](#shell-tips--tricks)
10. [Robotics Essentials (ROS 2)](#robotics-essentials-ros-2)
11. [Quick Reference Cheatsheet](#quick-reference-cheatsheet)

------

## Why the Terminal?

Most robotics frameworks (ROS, ROS 2, Gazebo), dev tools, and build systems live and breathe in the terminal. The sooner you get comfortable here, the faster you'll move. GUI tools are great — but when your robot's running headless on an embedded board, the terminal is all you've got.

------

## Navigating the File System

Linux organizes everything as a tree starting from `/` (root). Your home folder is `~/` (short for `/home/your-username`).

| Command    | What it does                                  | Example          |
| ---------- | --------------------------------------------- | ---------------- |
| `pwd`      | Print Working Directory — shows where you are | `pwd`            |
| `ls`       | List contents of current directory            | `ls`             |
| `ls -la`   | Detailed list including hidden files          | `ls -la`         |
| `cd <dir>` | Change Directory                              | `cd Documents`   |
| `cd ..`    | Go up one level                               | `cd ..`          |
| `cd ~`     | Go to home directory                          | `cd ~`           |
| `cd -`     | Go back to previous directory                 | `cd -`           |
| `tree`     | Show directory structure as a tree            | `tree ~/ros2_ws` |

**Try it:**

```bash
pwd           # See where you are
ls -la ~      # See everything in your home folder
cd /          # Go to the root of the filesystem
ls            # See the top-level folders
cd ~          # Come back home
```

> 💡 **Tab Completion** — Press `Tab` while typing a path to auto-complete. Double-tap `Tab` to see all options.

------

## Working with Files & Directories

| Command              | What it does                        | Example                          |
| -------------------- | ----------------------------------- | -------------------------------- |
| `mkdir <name>`       | Make a new directory                | `mkdir my_project`               |
| `mkdir -p a/b/c`     | Make nested directories at once     | `mkdir -p ros2_ws/src`           |
| `touch <file>`       | Create an empty file                | `touch hello.py`                 |
| `cp <src> <dest>`    | Copy a file                         | `cp notes.txt backup.txt`        |
| `cp -r <dir> <dest>` | Copy a directory recursively        | `cp -r project/ project_backup/` |
| `mv <src> <dest>`    | Move or rename a file               | `mv old.txt new.txt`             |
| `rm <file>`          | Delete a file                       | `rm temp.txt`                    |
| `rm -r <dir>`        | Delete a directory and its contents | `rm -r old_project/`             |
| `rmdir <dir>`        | Remove an empty directory           | `rmdir empty_folder`             |

> ⚠️ **Warning:** There is no Recycle Bin in the terminal. `rm` is permanent. Double-check before you delete!

**Try it:**

```bash
mkdir -p ~/practice/subdir     # Create nested folders
touch ~/practice/hello.txt     # Create a file
cp ~/practice/hello.txt ~/practice/subdir/   # Copy it
ls ~/practice/subdir/          # Confirm the copy
rm ~/practice/hello.txt        # Delete the original
```

------

## Viewing & Editing Files

### Viewing Files

| Command             | What it does                              | Example                   |
| ------------------- | ----------------------------------------- | ------------------------- |
| `cat <file>`        | Print entire file contents                | `cat notes.txt`           |
| `less <file>`       | Scroll through a file (press `q` to quit) | `less /etc/os-release`    |
| `head <file>`       | Show first 10 lines                       | `head log.txt`            |
| `head -n 20 <file>` | Show first N lines                        | `head -n 20 log.txt`      |
| `tail <file>`       | Show last 10 lines                        | `tail log.txt`            |
| `tail -f <file>`    | **Live-follow** a file as it updates      | `tail -f /var/log/syslog` |
| `wc -l <file>`      | Count lines in a file                     | `wc -l data.csv`          |

### Searching in Files

| Command                   | What it does                      | Example                             |
| ------------------------- | --------------------------------- | ----------------------------------- |
| `grep "text" <file>`      | Find lines containing text        | `grep "error" log.txt`              |
| `grep -r "text" <dir>`    | Search recursively in a directory | `grep -r "import rclpy" ~/ros2_ws/` |
| `grep -i "text" <file>`   | Case-insensitive search           | `grep -i "warning" log.txt`         |
| `find <dir> -name "*.py"` | Find files by name/pattern        | `find ~/ros2_ws -name "*.py"`       |

### Text Editors

```bash
nano <file>      # Beginner-friendly terminal editor
                 # Ctrl+O to save, Ctrl+X to exit

vim <file>       # Powerful but has a learning curve
                 # Press i to insert, Esc then :wq to save & quit

code <file>      # VS Code (if installed) — opens in GUI
```

> 💡 **Recommendation:** Start with `nano`. Learn `vim` when you're ready — it's everywhere, even on minimal systems.

------

## Permissions & Ownership

Every file in Linux has an owner and a set of permissions: **read (r)**, **write (w)**, **execute (x)** — for the owner, group, and others.

```
-rwxr-xr-x  1 user group  1234 Jun 09 10:00 my_script.py
 ^^^------       ↑
 owner perms   file owner
    ^^^---
    group perms
       ^^^
       others perms
```

| Command                   | What it does                        | Example                      |
| ------------------------- | ----------------------------------- | ---------------------------- |
| `ls -l`                   | View file permissions               | `ls -l`                      |
| `chmod +x <file>`         | Make a file executable              | `chmod +x launch.sh`         |
| `chmod 755 <file>`        | Set permissions numerically         | `chmod 755 script.sh`        |
| `chown user:group <file>` | Change file owner                   | `chown robot:robot data.txt` |
| `sudo <command>`          | Run a command as superuser (admin)  | `sudo apt update`            |
| `sudo su`                 | Switch to root user (use carefully) | `sudo su`                    |

> 💡 **Rule of thumb:** If a command says "Permission denied", you probably need `sudo` in front of it.

------

## Package Management (apt)

`apt` is Ubuntu/Debian's package manager — your app store for the terminal.

| Command                  | What it does                           |
| ------------------------ | -------------------------------------- |
| `sudo apt update`        | Refresh the list of available packages |
| `sudo apt upgrade`       | Upgrade all installed packages         |
| `sudo apt install <pkg>` | Install a package                      |
| `sudo apt remove <pkg>`  | Uninstall a package                    |
| `sudo apt autoremove`    | Clean up unused packages               |
| `apt search <keyword>`   | Search for a package                   |
| `apt show <pkg>`         | Show details about a package           |
| `dpkg -l`                | List all installed packages            |

**Example workflow:**

```bash
sudo apt update                    # Always update first
sudo apt install git               # Install git
sudo apt install python3-pip       # Install pip for Python 3
sudo apt install curl wget         # Useful download tools
```

------

## Process Management

| Command         | What it does                           | Example                                |
| --------------- | -------------------------------------- | -------------------------------------- |
| `ps aux`        | List all running processes             | `ps aux`                               |
| `top`           | Live view of running processes         | `top`                                  |
| `htop`          | Better version of top (install first)  | `htop`                                 |
| `kill <PID>`    | Kill a process by ID                   | `kill 1234`                            |
| `kill -9 <PID>` | Force-kill a process                   | `kill -9 1234`                         |
| `pkill <name>`  | Kill process by name                   | `pkill gazebo`                         |
| `Ctrl + C`      | Stop a running process in terminal     | —                                      |
| `Ctrl + Z`      | Pause a process (send to background)   | —                                      |
| `bg`            | Resume paused process in background    | `bg`                                   |
| `fg`            | Bring background process to foreground | `fg`                                   |
| `<command> &`   | Run command in background              | `ros2 launch my_pkg nodes.launch.py &` |

------

## Networking Basics

| Command                    | What it does                           | Example                               |
| -------------------------- | -------------------------------------- | ------------------------------------- |
| `ping <host>`              | Test network connectivity              | `ping google.com`                     |
| `ifconfig`                 | Show network interfaces & IPs          | `ifconfig`                            |
| `ip addr`                  | Modern way to see IP addresses         | `ip addr`                             |
| `ssh user@host`            | Connect to a remote machine            | `ssh pi@192.168.1.10`                 |
| `scp file user@host:/path` | Copy file to remote machine            | `scp map.yaml pi@192.168.1.10:~/`     |
| `wget <url>`               | Download a file from the web           | `wget https://example.com/file.zip`   |
| `curl <url>`               | Fetch data from a URL                  | `curl https://api.example.com/status` |
| `netstat -tulnp`           | Show open ports and listening services | `netstat -tulnp`                      |

> 🤖 **Robotics note:** `ssh` is critical — you'll use it constantly to connect to robot computers (Raspberry Pi, Jetson Nano, etc.) over your network.

------

## Shell Tips & Tricks

### Redirection & Pipes

```bash
command > file.txt        # Redirect output to a file (overwrites)
command >> file.txt       # Append output to a file
command 2> errors.txt     # Redirect error output to a file
command1 | command2       # Pipe output of cmd1 into cmd2

# Examples
ls -la > directory_list.txt
cat log.txt | grep "error" | wc -l    # Count error lines in log
ros2 topic echo /scan | grep "inf"    # Filter lidar data
```

### Useful Shortcuts

| Shortcut   | Action                           |
| ---------- | -------------------------------- |
| `Ctrl + C` | Kill current process             |
| `Ctrl + Z` | Pause current process            |
| `Ctrl + L` | Clear the screen                 |
| `Ctrl + A` | Go to beginning of line          |
| `Ctrl + E` | Go to end of line                |
| `↑ / ↓`    | Scroll through command history   |
| `Ctrl + R` | Search command history           |
| `Tab`      | Auto-complete paths and commands |
| `!!`       | Repeat last command              |
| `sudo !!`  | Repeat last command with sudo    |

### Environment Variables

```bash
echo $HOME          # Print home directory path
echo $PATH          # Print executable search paths
export MY_VAR=hello # Set a variable for current session
echo $MY_VAR        # Use it

# Add to ~/.bashrc to make it permanent
echo 'export ROS_DOMAIN_ID=42' >> ~/.bashrc
source ~/.bashrc    # Reload config without restarting terminal
```

### Aliases — Create Your Own Shortcuts

```bash
# Add these to ~/.bashrc
alias ll='ls -la'
alias gs='git status'
alias src='source ~/.bashrc'
alias rosdep-install='rosdep install --from-paths src --ignore-src -r -y'
```

------

## Robotics Essentials (ROS 2)

> These commands assume you have **ROS 2 Humble** (or later) installed on Ubuntu 22.04.

### Setup

```bash
# Source ROS 2 environment (add to ~/.bashrc to auto-run)
source /opt/ros/humble/setup.bash

# Source your workspace
source ~/ros2_ws/install/setup.bash

# Check ROS 2 is working
ros2 --version
```

### Core ROS 2 Commands

| Command                                 | What it does                      |
| --------------------------------------- | --------------------------------- |
| `ros2 run <pkg> <node>`                 | Run a node from a package         |
| `ros2 launch <pkg> <launch_file>`       | Launch multiple nodes at once     |
| `ros2 node list`                        | List all running nodes            |
| `ros2 node info <node>`                 | Show info about a node            |
| `ros2 topic list`                       | List all active topics            |
| `ros2 topic echo <topic>`               | Print live messages on a topic    |
| `ros2 topic hz <topic>`                 | Show publish frequency of a topic |
| `ros2 topic pub <topic> <type> <data>`  | Manually publish to a topic       |
| `ros2 service list`                     | List all available services       |
| `ros2 service call <srv> <type> <data>` | Call a service                    |
| `ros2 param list`                       | List all parameters               |
| `ros2 param get <node> <param>`         | Get a parameter value             |
| `ros2 bag record -a`                    | Record all topics to a bag file   |
| `ros2 bag play <bagfile>`               | Replay a recorded bag             |

### Building a Workspace

```bash
cd ~/ros2_ws
colcon build                          # Build all packages
colcon build --packages-select <pkg>  # Build a specific package
source install/setup.bash             # Source after every build
```

### Creating a New Package

```bash
cd ~/ros2_ws/src
ros2 pkg create my_robot_pkg --build-type ament_python --dependencies rclpy std_msgs
cd ~/ros2_ws
colcon build --packages-select my_robot_pkg
source install/setup.bash
```

### Git — Version Control (Essential for Robotics Projects)

```bash
git clone <url>           # Download a repository
git status                # Check what's changed
git add <file>            # Stage a file for commit
git add .                 # Stage all changes
git commit -m "message"   # Commit with a message
git push                  # Push to remote (GitHub/GitLab)
git pull                  # Pull latest changes
git log --oneline         # Compact commit history
git branch                # List branches
git checkout -b new-feat  # Create & switch to a new branch
```

### Python Virtual Environments

```bash
python3 -m venv myenv          # Create a virtual environment
source myenv/bin/activate      # Activate it
pip install numpy opencv-python # Install packages inside it
deactivate                     # Exit the environment
```

------

## Quick Reference Cheatsheet

```
NAVIGATION          FILES & DIRS         VIEWING            SYSTEM
pwd                 mkdir <dir>          cat <file>         sudo <cmd>
ls / ls -la         touch <file>         less <file>        sudo apt update
cd <dir>            cp <src> <dst>       head/tail <file>   sudo apt install
cd .. / cd ~        mv <src> <dst>       grep "x" <file>    ps aux / top
                    rm <file>            find . -name       kill <PID>
                    rm -r <dir>          nano/vim <file>    Ctrl+C

NETWORK             GIT                  ROS 2              TIPS
ping <host>         git clone <url>      ros2 run           Tab → autocomplete
ssh user@host       git status           ros2 launch        ↑↓ → history
scp file host:path  git add .            ros2 topic list    Ctrl+R → search
wget <url>          git commit -m ""     ros2 topic echo    cmd | grep "x"
ip addr             git push/pull        colcon build       cmd > file.txt
```

------

## 🚀 What's Next?

Once you're comfortable with these, explore:

- **Bash scripting** — automate repetitive tasks with `.sh` scripts
- **tmux / screen** — manage multiple terminal sessions (super useful for robots)
- **Docker** — containerize your robot software
- **ROS 2 Navigation Stack (Nav2)** — autonomous navigation
- **Gazebo / RViz** — simulate your robot before touching hardware

------

*Happy hacking! The best way to learn the terminal is to live in it.* 🤖