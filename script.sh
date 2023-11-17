#!/bin/bash

# Function to determine the device type
get_device_type() {
    # Check if the "raspberrypi" string is present in the hardware information
    if grep -q "raspberrypi" /proc/cpuinfo; then
        echo "Raspberry Pi"
    elif lsb_release -a 2>/dev/null | grep -q "Ubuntu"; then
        echo "Ubuntu Server"
    else
        echo "Unknown"
    fi
}

# Determine the device type
device_type=$(get_device_type)

# Define the username for the new users
managementacc="<managementacc>"
useracc="<useracc>"

# Define the SSH key format and encryption length
ssh_key_format="rsa"  # Change to your preferred format (rsa, ed25519, etc.)
ssh_key_length=4096   # Change to your preferred encryption length

# Define the default user for Ubuntu and Raspberry Pi
default_user=""
if [ "$device_type" == "Ubuntu Server" ]; then
    default_user="root"
elif [ "$device_type" == "Raspberry Pi" ]; then
    default_user="pi"
fi

# Create users and handle potential existing user cases
sudo id -u $managementacc &>/dev/null || sudo useradd -m $managementacc
sudo id -u $useracc &>/dev/null || sudo useradd -m $useracc

# Function to remove existing SSH keys, generate new keys, disable user, and disable password authentication
setup_user() {
    local user_name=$1
    # Remove existing SSH keys
    sudo -u $user_name rm -f "/home/$user_name/.ssh/id_$ssh_key_format"*
    # Generate new SSH keys
    sudo -u $user_name ssh-keygen -t $ssh_key_format -b $ssh_key_length -N "" -f "/home/$user_name/.ssh/id_$ssh_key_format"
    echo "Generated new SSH keys for user: $user_name"
    # Disable password-based authentication
    sudo sed -i "/^$user_name/s/[^:]*:[^:]*:/\*:/2" /etc/shadow
    echo "Disabled password-based authentication for user: $user_name"
}

# Setup managementacc user
setup_user $managementacc

# Setup useracc user
setup_user $useracc

# Disable SSH login for the default user
if [ ! -z "$default_user" ]; then
    sudo passwd -l $default_user
    echo "Disabled SSH login for the default user: $default_user"
else
    echo "No default user found for this device type."
fi

echo "User setup, new SSH keys generated, password-based authentication disabled, and default user disabled on $device_type."
