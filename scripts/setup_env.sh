function get_computer_id {
  hostname=$(cat "/etc/hostname")
  if [[ "$hostname" =~ ^.+-ros([0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "Hello"
  fi
}

ID=$(get_computer_id)

echo "export ROS_DOMAIN_ID=$ID" >> $HOME/setup_ros.env
echo "export RMW_IMPLEMENTATION=rmw_fastrtps_cpp" >> $HOME/setup_ros.env

echo 'source "$HOME/setup_ros.env"' >> $HOME/.bashrc