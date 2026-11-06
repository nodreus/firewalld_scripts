#!/bin/bash
# Default deny public zone 
# SSH rule(s) allowed to specific IP / subnet
 
set -euo pipefail

# SSH Configuration
SSHIP="192.168.1.1"	# replace with your machines IP
#SSHIP2="192.168.1.2"	# replace with a second machines IP or subnet range
SSHPORT="22"
SSHPROTO="tcp"
#
echo -e "\033[0;32m                                                 
                                           █     
  ▄▄▄   ▄▄▄▄    ▄▄▄   ▄ ▄▄    ▄▄▄    ▄▄▄   █ ▄▄  
 █▀ ▀█  █▀ ▀█  █▀  █  █▀  █  █   ▀  █   ▀  █▀  █ 
 █   █  █   █  █▀▀▀▀  █   █   ▀▀▀▄   ▀▀▀▄  █   █ 
 ▀█▄█▀  ██▄█▀  ▀█▄▄▀  █   █  ▀▄▄▄▀  ▀▄▄▄▀  █   █ 
        █                                        
        ▀                                        \033[0m"
#
# 1. SSH allow-rule first
sudo firewall-cmd --permanent --zone=public --add-rich-rule="rule family=\"ipv4\" source address=\"$SSHIP\" service name=\"ssh\" accept"
#sudo firewall-cmd --permanent --zone=public --add-rich-rule="rule family=\"ipv4\" source address=\"$SSHIP2\" port port=\"$SSHPORT\" protocol=\"$SSHPROTO\" accept"

# 2. Other config changes
#sudo firewall-cmd --permanent --zone=public --remove-service=cockpit
sudo firewall-cmd --set-default-zone=public

# 3. Set the drop target permanently
sudo firewall-cmd --permanent --zone=public --set-target=DROP

# 4. Apply everything in one shot
sudo firewall-cmd --reload
sudo firewall-cmd --list-all

# 5. Remove rules
# sudo firewall-cmd --remove-rich-rule='rule family="ipv4" source address="" port port="" protocol="" accept' --permanent

# 6. Raw rules
#
# Service port to specific IP range
#
# sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.20.1.0/24" port port="8080" protocol="tcp" accept'
#
# SSH to specific IP range
#
# sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.50" service name="ssh" accept'
echo -e "\033[0;32mScript finished\033[0m"
