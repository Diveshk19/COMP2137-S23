#!/bin/bash
set -e  # Exit script on first error, making the script more robust by preventing it from executing subsequent commands if a command fails.

# Function to execute commands on the remote system via SSH
ssh_exec() {
    # SSH command to connect to a remote server. If an error occurs during SSH, it will print an error message and stop execution.
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 remoteadmin@"$1" "$2" &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Error: SSH command failed"
        exit 1
    fi
}

# Function to update IP and hostname
update_ip_and_hostname() {
    # This function updates the IP address and hostname on the remote server.
    local TARGET_MGMT="$1"
    local TARGET_LAN="$2"
    local HOSTNAME="$3"
    # Deletes the existing LAN IP address, sets the hostname, and adds the new LAN IP address
    ssh_exec "$TARGET_MGMT" "sudo ip addr del $TARGET_LAN/24 dev eth0 || true"
    ssh_exec "$TARGET_MGMT" "sudo hostnamectl set-hostname $HOSTNAME"
    ssh_exec "$TARGET_MGMT" "sudo ip addr add $TARGET_LAN/24 dev eth0"
}

# Function to update /etc/hosts and install and configure UFW
update_hosts_and_ufw() {
    # This function updates the /etc/hosts file on the remote server and installs and configures UFW (Uncomplicated Firewall).
    local TARGET_MGMT="$1"
    local TARGET_LAN="$2"
    local HOSTNAME="$3"
    local ALLOW_PORTS="$4"
    # Writes the LAN IP and hostname to the /etc/hosts file, installs UFW, and configures UFW to allow certain ports.
    ssh_exec "$TARGET_MGMT" "echo '$TARGET_LAN $HOSTNAME' | sudo tee -a /etc/hosts"
    ssh_exec "$TARGET_MGMT" "sudo apt update -qq && sudo apt install -y ufw"
    ssh_exec "$TARGET_MGMT" "sudo ufw allow $ALLOW_PORTS"
}

# Function to configure rsyslog
configure_rsyslog() {
    # This function configures the rsyslog service on the remote server.
    local TARGET_MGMT="$1"
    local CONF_COMMANDS="$2"
    # Updates the rsyslog configuration and restarts the rsyslog service
    ssh_exec "$TARGET_MGMT" "$CONF_COMMANDS"
    ssh_exec "$TARGET_MGMT" "sudo systemctl restart rsyslog"
}

# Network and host parameters
TARGET1_MGMT="172.16.1.10"
TARGET1_LAN="192.168.1.3"
TARGET2_MGMT="172.16.1.11"
TARGET2_LAN="192.168.1.4"
NMS_HOSTNAME="loghost"
WEBHOST_HOSTNAME="webhost"

# Checking target availability
# For each target, it pings the target to check if it's reachable. If it's not reachable, it prints an error message and stops execution.
for TARGET in "$TARGET1_MGMT" "$TARGET2_MGMT"; do
    if ! ping -c 1 "$TARGET" &>/dev/null; then
        echo "Error: Unable to reach target ($TARGET)"
        exit 1
    fi
done

# Tasks for target1-mgmt
# Calls the functions defined above to perform a series of operations on target1-mgmt
update_ip_and_hostname "$TARGET1_MGMT" "$TARGET1_LAN" "$NMS_HOSTNAME"
update_hosts_and_ufw "$TARGET1_MGMT" "$TARGET2_LAN" "$WEBHOST_HOSTNAME" "from 172.16.1.0/24 to any port 514 proto udp"
configure_rsyslog "$TARGET1_MGMT" "sudo sed -i 's/#module(load=\"imudp\"/module(load=\"imudp\"/' /etc/rsyslog.conf && sudo sed -i 's/#input(type=\"imudp\" port=\"514\"/input(type=\"imudp\" port=\"514\"/' /etc/rsyslog.conf"

# Tasks for target2-mgmt
# Calls the functions defined above to perform a series of operations on target2-mgmt
update_ip_and_hostname "$TARGET2_MGMT" "$TARGET2_LAN" "$WEBHOST_HOSTNAME"
update_hosts_and_ufw "$TARGET2_MGMT" "$TARGET1_LAN" "$NMS_HOSTNAME" "80/tcp"
ssh_exec "$TARGET2_MGMT" "sudo apt update -qq && sudo apt install -y apache2"
configure_rsyslog "$TARGET2_MGMT" "echo '*.* @$NMS_HOSTNAME' | sudo tee -a /etc/rsyslog.conf"

# Update local /etc/hosts file
# Writes the MGMT IP and hostname of target1-mgmt and target2-mgmt to the local /etc/hosts file
echo "$TARGET1_MGMT $NMS_HOSTNAME" | sudo tee -a /etc/hosts
echo "$TARGET2_MGMT $WEBHOST_HOSTNAME" | sudo tee -a /etc/hosts

# Verify configurations
# Verifies if the operations were successful by trying to access the default Apache page from WEBHOST_HOSTNAME and checking if logs from WEBHOST_HOSTNAME are present on NMS_HOSTNAME
if curl -s "http://$WEBHOST_HOSTNAME" | grep -q "Apache2 Ubuntu Default Page"; then
    if ssh remoteadmin@"$NMS_HOSTNAME" grep -q "$WEBHOST_HOSTNAME" /var/log/syslog; then
        echo "Configuration update succeeded."
    else
        echo "Configuration update failed. Cannot retrieve logs from $WEBHOST_HOSTNAME on $NMS_HOSTNAME."
    fi
else
    echo "Configuration update failed. Cannot retrieve default Apache web page from $WEBHOST_HOSTNAME."
fi

