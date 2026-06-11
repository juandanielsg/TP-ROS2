# installer visual studio code depuis ubuntu software

sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git-all
sudo apt install -y emacs
echo "alias emacs=\"emacs -nw\"" >> ~/.bashrc
sudo apt install -y curl

sudo apt install -y software-properties-common
sudo add-apt-repository universe -y
sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update -y
sudo apt upgrade -y

sudo apt install -y ros-humble-desktop
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source /opt/ros/humble/setup.bash
sudo apt install -y ros-dev-tools
sudo rosdep init
rosdep update
source ~/.bashrc
sudo apt install -y ros-humble-turtlebot4-desktop
mkdir -p ~/turtlebot4_ws/src
cd ~/turtlebot4_ws/src
git clone https://github.com/turtlebot/turtlebot4.git -b humble
cd ~/turtlebot4_ws
rosdep install --from-path src -yi --rosdistro humble
colcon build --symlink-install
sudo apt install ros-humble-turtlebot4-navigation -y
echo "source ~/turtlebot4_ws/install/setup.bash" >> ~/.bashrc
cd ~
git clone https://github.com/moogly-jungle/TP_ROS.git
echo "L'installation est terminée ! Have fun ..."
