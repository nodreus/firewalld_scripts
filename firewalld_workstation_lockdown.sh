#!/bin/bash
#firwalld_workstation_lockdown.sh - Total workstation lockdown: deny-by-default firewall, no exposed services, network hardening
#Fedora 45
#Linux Kernel 7.2.13-200.fc44.x86_64
#GNU Bash 5.3.9(1)-release (x86_64-redhat-linux-gnu)
#Dependencies: firewalld, iproute2, systemd
#Execution: root (wheel)
#Compatability: Fedora, Debian, RHEL
read -p "[CAUTION]: Executing this script will disrupt your ability to ssh or remote in to this machine. Would you like to proceed? (y/n): " response
if [[ "${response,,}" != "y" && "${response,,}" != "yes" ]]; then
    echo "Operation canceled."
    exit 1
fi
#Script logic
echo -e "\033[0;32mfirewalld
** * *  *
  *   **
    *
     *

      **
        *
   *
*   *


 **      \033[0m"
#
sudo dnf install firewalld -y
# Delete rich rules
sudo firewall-cmd --permanent --list-rich-rules |
while IFS= read -r rule; do
    sudo firewall-cmd --permanent --remove-rich-rule="$rule"
done
sudo firewall-cmd --reload
sleep 1
# Default deny public zone
sudo firewall-cmd --set-default-zone=public
sudo firewall-cmd --permanent --zone=public --set-target=DROP
sleep 1
# Remove rules
# sudo firewall-cmd --remove-rich-rule='rule family="ipv4" source address="" port port="" protocol="" accept' --permanent
#sudo firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address=#"10.20.0.0/24" port port="6967" protocol="tcp" accept' && sudo firewall-cmd --reload
for s in $(sudo firewall-cmd --permanent --zone=public --list-services); do
  sudo firewall-cmd --permanent --zone=public --remove-service="$s"
done
sudo firewall-cmd --reload
sleep 1
# Make every NetworkManager connection follow the default zone
for c in $(nmcli -g UUID connection show); do
  sudo nmcli connection modify "$c" connection.zone ""
done
sleep 1
# Strip ports and masquerading from public, not just services
for p in $(sudo firewall-cmd --permanent --zone=public --list-ports); do
  sudo firewall-cmd --permanent --zone=public --remove-port="$p"
done
sudo firewall-cmd --permanent --zone=public --remove-masquerade
sleep 1
# Log dropped packets (view with: journalctl -k -g DROP)
sudo firewall-cmd --set-log-denied=unicast
sleep 1
# Kernel network hardening
sudo tee /etc/sysctl.d/90-hardening.conf >/dev/null <<'EOF'
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1
EOF
sudo sysctl --system >/dev/null
sleep 1
# Turn off LLMNR/mDNS name poisoning
sudo mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nLLMNR=no\nMulticastDNS=no\n' | sudo tee /etc/systemd/resolved.conf.d/90-hardening.conf >/dev/null
sudo systemctl restart systemd-resolved
sleep 1
# Stop the exposed services themselves
sudo systemctl disable --now sshd cockpit.socket cups-browsed avahi-daemon 2>/dev/null
sleep 1
# (OPTIONAL, off by default) outbound allowlist
# Breaks anything not listed (VPNs, mail clients, git over SSH...). Uncomment to use.
# sudo firewall-cmd --permanent --new-policy=egress
# sudo firewall-cmd --permanent --policy=egress --add-ingress-zone=HOST
# sudo firewall-cmd --permanent --policy=egress --add-egress-zone=ANY
# sudo firewall-cmd --permanent --policy=egress --set-target=REJECT
# for s in dns http https ntp dhcp dhcpv6; do
#   sudo firewall-cmd --permanent --policy=egress --add-service=$s
# done
# sudo firewall-cmd --permanent --policy=egress --add-protocol=ipv6-icmp
sleep 1
# Reload
sudo firewall-cmd --reload
# Re-apply zone changes to active connections
for d in $(nmcli -g DEVICE connection show --active); do
  sudo nmcli device reapply "$d" >/dev/null 2>&1
done
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
sleep 2
echo -e "\033[0;32mFirewall configuration complete. Reboot to reload active SSH sessions.\033[0m"
