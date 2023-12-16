# reportfunctions.sh

# Function to generate CPU report
function cpureport() {
    echo "=== CPU Report ==="
    
    # Get CPU manufacturer and model
    local cpu_manufacturer=$(lscpu | grep "Vendor ID" | awk '{print $3}')
    local cpu_model=$(lscpu | grep "Model name" | awk '{$1=""; $2=""; print $0}')
    
    # Get CPU architecture
    local cpu_architecture=$(lscpu | grep "Architecture" | awk '{print $2}')
    
    # Get CPU core count
    local cpu_core_count=$(lscpu | grep "Core(s) per socket" | awk '{print $4}')
    
    # Get CPU maximum speed
    local cpu_max_speed=$(lscpu | grep "Max Speed" | awk '{print $3}')
    
    # Get Sizes of caches (L1, L2, L3)
    local l1_cache=$(lscpu | grep "L1d cache" | awk '{print $3}')
    local l2_cache=$(lscpu | grep "L2 cache" | awk '{print $3}')
    local l3_cache=$(lscpu | grep "L3 cache" | awk '{print $3}')
    
    echo "Title: CPU Information"
    echo "Manufacturer and Model: $cpu_manufacturer $cpu_model"
    echo "Architecture: $cpu_architecture"
    echo "Core Count: $cpu_core_count"
    echo "Maximum Speed: $cpu_max_speed"
    echo "L1 Cache: $l1_cache"
    echo "L2 Cache: $l2_cache"
    echo "L3 Cache: $l3_cache"
}



# Function to generate computer report
function computerreport() {
    echo "=== Computer Report ==="
    
    # Get computer manufacturer
    local computer_manufacturer=$(dmidecode -s system-manufacturer)
    
    # Get computer model/description
    local computer_model=$(dmidecode -s system-product-name)
    
    # Get computer serial number
    local serial_number=$(dmidecode -s system-serial-number)
    
    echo "Title: Computer Information"
    echo "Manufacturer: $computer_manufacturer"
    echo "Model/Description: $computer_model"
    echo "Serial Number: $serial_number"
}


# Function to generate OS report
function osreport() {
    echo "=== OS Report ==="
    
    # Get Linux distribution
    local linux_distro=$(lsb_release -is)
    
    # Get distribution version
    local distro_version=$(lsb_release -rs)
    
    echo "Title: OS Information"
    echo "Linux Distro: $linux_distro"
    echo "Distro Version: $distro_version"
}



# Function to generate RAM report
function ramreport() {
    echo "=== RAM Report ==="
    
    # Get total installed RAM size
    local total_ram_size=$(free -h | awk '/^Mem:/ {print $2}')
    
    # Print table header
    printf "%-20s %-20s %-15s %-15s %-30s\n" \
        "Manufacturer" "Model/Name" "Size" "Speed" "Physical Location"
    
    # Iterate through each memory component
    while read -r manufacturer model size speed location; do
        # Print table row
        printf "%-20s %-20s %-15s %-15s %-30s\n" \
            "$manufacturer" "$model" "$size" "$speed" "$location"
    done < <(dmidecode -t memory | awk -F: '/Manufacturer:|Product Name:|Size:|Speed:|Locator:/ {
                sub(/^ +/, "", $2);
                printf "%s ", $2
            } 
            /^$/ { print "" }'
        )
    
    # Print total RAM size
    echo "Total RAM Size: $total_ram_size"
}



# Function to generate video report
function videoreport() {
    echo "=== Video Report ==="
    
    # Get video card/chipset manufacturer
    local video_manufacturer=$(lspci | grep -i vga | awk -F" " '{print $5}')
    
    # Get video card/chipset description or model
    local video_model=$(lspci | grep -i vga | awk -F": " '{print $2}')
    
    echo "Title: Video Information"
    echo "Manufacturer: $video_manufacturer"
    echo "Description/Model: $video_model"
}


# Function to generate disk report
function diskreport() {
    echo "=== Disk Report ==="
    
    # Print table header
    printf "%-20s %-20s %-15s %-15s %-20s %-20s %-20s\n" \
        "Manufacturer" "Model" "Size" "Partition" "Mount Point" "Filesystem Size" "Free Space"
    
    # Iterate through each disk drive
    while read -r manufacturer model size partition mountpoint filesystemsize freespace; do
        # Print table row
        printf "%-20s %-20s %-15s %-15s %-20s %-20s %-20s\n" \
            "$manufacturer" "$model" "$size" "$partition" "$mountpoint" "$filesystemsize" "$freespace"
    done < <(lsblk -o NAME,MODEL,SIZE,MOUNTPOINT,FSTYPE,FSSIZE,FSUSED,FSAVAIL -n -e 2,7,11,65,66,67,68,69)
}



# Function to generate network report
function networkreport() {
    echo "=== Network Report ==="
    
    # Print table header
    printf "%-20s %-20s %-15s %-15s %-25s %-15s %-15s %-20s\n" \
        "Interface" "Manufacturer" "Description" "Link State" "Speed" "IP Addresses" "Bridge Master" "DNS"
    
    # Iterate through each network interface
    while read -r interface manufacturer description linkstate speed ipaddresses bridgemaster dns; do
        # Print table row
        printf "%-20s %-20s %-15s %-15s %-25s %-15s %-15s %-20s\n" \
            "$interface" "$manufacturer" "$description" "$linkstate" "$speed" "$ipaddresses" "$bridgemaster" "$dns"
    done < <(ip -o link show | awk -F": " '
            { 
                interface=$2
                manufacturer=""
                description=""
                linkstate=""
                speed=""
                ipaddresses=""
                bridgemaster=""
                dns=""
            }
            /link\/ether/ {
                getline
                if ($2 != "lo") {
                    manufacturer=$(ethtool -i $2 | awk -F": " '/driver/ {print $2}')
                    description=$(ethtool $2 | awk -F": " '/Settings for/ {print $2}')
                    linkstate=$(ip link show $2 | grep "state" | awk '{print $9}')
                    speed=$(ethtool $2 | awk -F": " '/Speed/ {print $2}')
                    ipaddresses=$(ip addr show $2 | awk '/inet / {print $2}')
                    bridgemaster=$(brctl show | awk -v iface=$2 'index($4, iface) {print $1}')
                    dns=$(nmcli dev show $2 | awk -F": " '/IP4.DNS/ {print $2}')
                }
            }
            END {
                if (interface != "") {
                    print interface, manufacturer, description, linkstate, speed, ipaddresses, bridgemaster, dns
                }
            }' | column -t)
}


# Function to save error message with timestamp into /var/log/systeminfo.log
# and display the error message to the user on stderr
function errormessage() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local error_message="$1"
    
    # Save error message to log file
    echo "[$timestamp] $error_message" >> /var/log/systeminfo.log
    
    # Display error message to user on stderr
    echo "Error: $error_message" >&2
}





