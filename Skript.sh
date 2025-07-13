#!/bin/bash

# Define the root directory of your project (where Skript.sh is located)
# This assumes you run the script from within the project's root directory,
# or you can set an absolute path here if needed.
# For example, if your cloned repository is at /mnt/c/MyProject/, set BASE_DIR="/mnt/c/MyProject"
# If you run the script from its current location, `pwd` is fine.
BASE_DIR="$(pwd)" 

PROXMOX_IP="..." # Your Proxmox server IP address

if [ "$PROXMOX_IP" = "..." ] || [ -z "$PROXMOX_IP" ]; then
    echo "Error: PROXMOX_IP is not set."
    echo "Edit the script and set PROXMOX_IP to the IP address of your Proxmox server,"
    echo "e.g.: PROXMOX_IP=\"199.168.1.100\""
    exit 1
fi

# --- Terraform Section ---
# 0) Navigate to the Terraform directory and run Terraform commands
echo "Navigating to Terraform directory: $BASE_DIR/Terraform"
cd "$BASE_DIR/Terraform" || { echo "Error changing to directory $BASE_DIR/Terraform"; exit 1; }

# 1) Run Terraform
echo "Running Terraform..."
terraform init
terraform apply -auto-approve

# 2) Get LXC ID from Terraform output (run from Terraform directory)
echo "Getting VMID..."
VMID=$(terraform show | grep 'id' | grep -oP '"host/lxc/\d+"' | grep -oP '\d+')
echo "VMID is: $VMID"

# --- Return to base directory for SSH/Ansible operations ---
echo "Returning to base directory: $BASE_DIR"
cd "$BASE_DIR" || { echo "Error returning to base directory $BASE_DIR"; exit 1; }


# 3) Start LXC in Proxmox via SSH
echo "Starting LXC on Proxmox..."
ssh root@$PROXMOX_IP "pct start $VMID"

# 4) Get LXC IP address
echo "Getting IP address of LXC $VMID..."
IP_ADDRESS=$(ssh root@$PROXMOX_IP "pct exec $VMID -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
echo "IP address of container $VMID is: $IP_ADDRESS"

# 5) Add IP address to hosts.ini (now in ansible/ subdirectory)
echo "Adding IP address to hosts.ini..."
HOSTS_FILE="$BASE_DIR/ansible/hosts.ini" # Path updated to reflect ansible/ subdirectory

# If hosts.ini does not exist, create it; if it exists, add the new IP address
# Note: You might want to implement logic to clear existing entries for the IP_ADDRESS
# or create a new file for each run if multiple deployments are expected.
if [ ! -f "$HOSTS_FILE" ]; then
    echo "[server1]" > "$HOSTS_FILE"
fi
# Add entry for the new server or container
echo "$IP_ADDRESS ansible_user=root ansible_ssh_private_key_file=/home/idk/.ssh/id_rsa" >> "$HOSTS_FILE"


# 6) Run Ansible playbooks (now in ansible/ subdirectory)
echo "Running Ansible playbooks..."
# Note: The playbooks themselves are referenced relative to the `ansible-playbook` command's execution directory,
# or by their full path. Since we are back in BASE_DIR, we use "ansible/PLAYBOOK_NAME.yml"
ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/01-Preinstall.yml" --limit "$IP_ADDRESS" -e "ansible_ssh_extra_args='-o StrictHostKeyChecking=no'"
#ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/02-PHP-7.4.yml" --limit "$IP_ADDRESS"
ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/02-PHP-8.1.yml" --limit "$IP_ADDRESS"
ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/03-MariaDB.yml" --limit "$IP_ADDRESS"
#ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/04-iTop-3.1.1.yml" --limit "$IP_ADDRESS"
#ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/04-iTop-3.1.2.yml" --limit "$IP_ADDRESS"
ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/04-iTop-3.2.0.yml" --limit "$IP_ADDRESS"
#ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/04-iTop-3.2.0-2.yml" --limit "$IP_ADDRESS"
ansible-playbook -i "$HOSTS_FILE" "$BASE_DIR/ansible/05-Toolkit.yml" --limit "$IP_ADDRESS"

# 7) Rename VM (SSH commands are relative to Proxmox, no path change needed here)
ITOP_VERSION=$(ssh root@$IP_ADDRESS "grep -oP \"(?<=define\('ITOP_CORE_VERSION', ')[^']+\" /var/www/html/itop/approot.inc.php")
PHP_VERSION=$(ssh root@$IP_ADDRESS "php -v | head -n 1 | grep -oP '\d+\.\d+'")
NEW_NAME="php${PHP_VERSION}-itop${ITOP_VERSION}-$(date +%Y%m%d-%H%M)"
echo "Renaming container to $NEW_NAME..."
ssh root@$PROXMOX_IP "pct set $VMID -hostname $NEW_NAME"

# 8) Clean up Terraform state (navigate back to Terraform directory for this)
echo "Cleaning up Terraform state..."
cd "$BASE_DIR/Terraform" || { echo "Error changing to directory $BASE_DIR/Terraform"; exit 1; }
terraform state rm proxmox_lxc.dynamic_container

# --- Return to base directory for final output ---
echo "Returning to base directory: $BASE_DIR"
cd "$BASE_DIR" || { echo "Error returning to base directory $BASE_DIR"; exit 1; }

# 9) Display IP address of the created LXC
echo "IP address of the created LXC: $IP_ADDRESS"