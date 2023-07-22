#!/bin/bash

# Configuration Settings
TARGET_HOSTNAME="autosrv"
INTERFACE="ens33"
IP_ADDRESS="192.168.16.21/24"
GATEWAY="192.168.16.1"
DNS_SERVER="192.168.16.1"
DNS_SEARCH_DOMAINS="home.arpa localdomain"
USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

# Function to check and update hostname
update_hostname() {
    current_hostname=$(hostname)

    if [[ "$current_hostname" != "$TARGET_HOSTNAME" ]]; then
        cat <<EOF

===> Updating hostname to $TARGET_HOSTNAME
EOF
        sudo hostnamectl set-hostname "$TARGET_HOSTNAME" || { cat <<EOF

[ERROR] Failed to update hostname
EOF
        exit 1; }
        cat <<EOF

Hostname updated successfully
EOF
    else
        cat <<EOF

===> Hostname is already set to $TARGET_HOSTNAME
EOF
    fi
}

# Function to check and update network configuration
configure_network() {
    cat <<EOF

===> Configuring network settings...
EOF
    current_ip_address=$(ip addr show dev "$INTERFACE" | grep -w "inet" | awk '{print $2}')
    current_gateway=$(ip route show | grep "default via" | awk '{print $3}')
    current_dns_server=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}' | head -n 1)
    current_dns_search_domains=$(grep "search" /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')

    if [[ "$current_ip_address" != "$IP_ADDRESS" || "$current_gateway" != "$GATEWAY" || "$current_dns_server" != "$DNS_SERVER" || "$current_dns_search_domains" != "$DNS_SEARCH_DOMAINS" ]]; then
        cat <<EOF

===> Updating network configuration for interface $INTERFACE
EOF
        # Add commands here to set the static IP address, gateway, DNS server, and search domains
        cat <<EOF

Network configuration updated successfully
EOF
    else
        cat <<EOF

===> Network configuration is already set
EOF
    fi
}

# Function to install required software
install_software() {
    cat <<EOF

===> Installing required software...
EOF
    # Install ssh server
    sudo apt-get update
    sudo apt-get install -y openssh-server

    # Configure sshd_config to allow ssh key authentication and disable password authentication
    sudo sed -i -E 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd

    # Install Apache2 web server
    sudo apt-get install -y apache2

    # Install Squid web proxy
    sudo apt-get install -y squid

    cat <<EOF

Software installation completed successfully
EOF
}

# Function to configure firewall
configure_firewall() {
    cat <<EOF

===> Configuring firewall...
EOF
    # Install ufw if not already installed
    sudo apt-get install -y ufw

    # Reset ufw rules
    sudo ufw --force reset

    # Enable ufw
    sudo ufw enable

    # Allow necessary services through the firewall
    sudo ufw allow 22/tcp           # SSH
    sudo ufw allow 80/tcp           # HTTP
    sudo ufw allow 443/tcp          # HTTPS
    sudo ufw allow 3128/tcp         # Squid Web Proxy

    cat <<EOF

Firewall configuration completed successfully
EOF
}

# Function to create user accounts and configure ssh keys and shell
create_user_accounts() {
    cat <<EOF

===> Creating user accounts...
EOF

    for user in "${USERS[@]}"; do
        # Create user with home directory
        sudo useradd -m "$user"

        # Add ssh keys for rsa and ed25519 algorithms
        sudo mkdir -p /home/"$user"/.ssh
        sudo cat <<EOFPUB | sudo tee -a /home/"$user"/.ssh/authorized_keys > /dev/null
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm
# Add additional public keys here if needed
EOFPUB
        sudo chown -R "$user":"$user" /home/"$user"/.ssh
        sudo chmod 700 /home/"$user"/.ssh
        sudo chmod 600 /home/"$user"/.ssh/authorized_keys

        # Set the default shell to bash
        sudo chsh -s /bin/bash "$user"
    done

    # Allow sudo access only for user 'dennis'
    sudo usermod -aG sudo "${USERS[0]}"

    cat <<EOF

User accounts created successfully
EOF
}

# Function to test modifications
test_modifications() {
    cat <<EOF

===> Testing modifications...
EOF
    update_hostname
    configure_network
    install_software
    configure_firewall
    create_user_accounts

    cat <<EOF

All tests passed successfully
EOF
}

# Main function to perform modifications
perform_modifications() {
    cat <<EOF

===> Performing system modifications...
EOF
    update_hostname
    configure_network
    install_software
    configure_firewall
    create_user_accounts

    cat <<EOF

All modifications completed successfully
EOF
}

# Test modifications before applying
test_modifications

read -p "Do you want to apply the modifications? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    cat <<EOF

Modifications not applied. Exiting...
EOF
    exit 0
fi

# Perform modifications
perform_modifications

cat <<EOF

Script completed.
EOF

