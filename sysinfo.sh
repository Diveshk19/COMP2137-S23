#!/bin/bash 
#ASSIGNMENT 1
#gathering system information by using three variables 

#below variable is assigned to get hostname from machine     
myhostname=$(hostname)
#below variable is used t get info os
myOS=$(source /etc/os-release && echo $PRETTY_NAME)
#next one we have used to get uptime
myuptime=$(uptime -p)

#gathering general information for the script like date and user who created it
#used $user to get username and stored it in valuable variable
myusername=$USER
# variable was used to get today's date
mydate=$(date)

#gathering hardware information
# command to get cpu info and stored it in variable
mycpu=$(sudo lshw -class processor | grep -m1 product)
# obtaining cpu speed by following variable which has command stored in it 
mycpuspeed=$(lscpu | awk -F': ' '/BogoMIPS/ {print $2" MHz"}')
#ram info stored in following variable  
myram=$(free -h | awk '/Mem:/ {print $2}')
# getting all the disks present in machine with model and size in M,G,K whichh represent mb,gb,kb
mydisks=$(lsblk -d --nodeps -o NAME,MODEL,SIZE)
# info about video controller
myvideo=$(lspci | grep -i 'VGA compatible controller' | awk -F': ' '{print $2}')

#gathering network information
#getting fqdn info by using hostname command
myFQDN=$(hostname -f)
#command for host address which is stored in respected variable
myhostaddress=$(hostname -I | awk '{print $1}')
# getting info abput gateway
mygatewayip=$(ip r | awk '/default via/ {print $3}')
# below variable assigned to a command which will help to get dns server information 
mydnsserver=$(cat /etc/resolv.conf | awk '/nameserver/ {print $2}')
# using awk command to get interface name details
myinterfacename=$(ip a | awk '/state UP/ {print $2}' | cut -d':' -f1)
# used the following variable in script to ip address details
myipaddress=$(ip a show dev $(ip r | awk '/default/ {print $5}') | awk '/inet / {print $2}')

#gathering information about system status
# getting information that how many users have logged in
myuserslog=$(who | cut -d' ' -f1 | sort | uniq)
# all the info about disk space in gb and mb which is represented by  g and m
mydiskspace=$(df -h --output=target,avail | tail -n+2)
# info about process count 
myprocesscount=$(ps -e --no-headers | wc -l)
# all the things for load averages is stored in next variable
myloadaverages=$(uptime | awk -F'average: ' '{print $2}')
# it has all info about how much memory is used and what is total memory , first output will give memory used and second will give total memory
mymemoryallocation=$(free -h | awk '/Mem/ {print $3,$2}')
# Script to display listening ports suitable for Linux.
mylisteningports=$(ss -tuln | awk 'NR>1 {print $5}')
# it is displaying ufw rules in output
myufwrules=$(sudo ufw show raw)

# there is one command whichwas giving  me blank output for my vm : sudo ufw status numbered | grep -v 'Status: active'

cat <<EOF
System Report generated by $myusername, $mydate


System Information
------------------
Hostname: $myhostname
OS:$myOS
Uptime: $myuptime

 
Hardware Information
--------------------
cpu:$mycpu
Speed:$mycpuspeed
Ram:$myram
Disk(s):$mydisks
Video:$myvideo


Network Information
-------------------
FQDN:$myFQDN
Host Address:$myhostaddress
Gateway IP:$mygatewayip
DNS Server:$mydnsserver
InterfaceName:$myinterfacename
IP Address:$myipaddress


System Status
-------------
Users Logged In:$myuserslog
Disk Space:$mydiskspace
Process Count:$myprocesscount
Load Averages:$myloadaverages
Memory Allocation:$mymemoryallocation
Listening Network Ports:$mylisteningports
UFW Rules:$myufwrules
EOF

#DONE 

