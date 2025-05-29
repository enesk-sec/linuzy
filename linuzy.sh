#!/bin/bash
# Linuzy - Linux Admin Toolkit
# Created by Enes K.
# Description: A modular Linux sysadmin tool for automation and hardening.
# Note: Some modules require root privileges.



# === Color Definitions ===
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No color



# === ASCII Logo ===
show_logo() {
        clear
        echo -e "${GREEN}"
        cat << "EOF"

██╗     ██╗███╗   ██╗██╗   ██╗███████╗██╗   ██╗
██║     ██║████╗  ██║██║   ██║╚══███╔╝╚██╗ ██╔╝
██║     ██║██╔██╗ ██║██║   ██║  ███╔╝  ╚████╔╝
██║     ██║██║╚██╗██║██║   ██║ ███╔╝    ╚██╔╝
███████╗██║██║ ╚████║╚██████╔╝███████╗   ██║
╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝

         Linuzy - Linux Admin Toolkit
                  by Enes K.
EOF
        echo -e "${NC}"
}



# === Main Menu ===
main_menu() {
	clear
	show_logo
	echo "1) 📦 System Updates"
	echo "2) ⚙️  Ansible Configuration"
	echo "3) 🔐 PAM Security Configuration"
	echo "4) 🛡️  Security Hardening"
	echo "5) 🌐 Network Configuration (nmcli)"
	echo "6) 📡 NFS + AutoFS Setup"
	echo "7) 💽 Create LVM from unused disk"
	echo "8) 💾 Backup & Snapshot Tool"
	echo "9) ⏰ Automation & Log Management (cron + logrotate)"
	echo "0) 🚪 Exit"
	echo ""
	read -p "Enter an option: " choice

	case $choice in
		1) system_updates ;;
		2) ansible_configuration ;;
		3) pam_configuration ;;
		4) security_hardening ;;
		5) network_config ;;
		6) nfs_autofs_setup ;;
		7) create_lvm ;;
		8) backup_tool ;;
		9) automation_menu ;;
		0) exit 0 ;;
		*) echo -e "${RED}Invalid option!${NC}" ; sleep 1 ; main_menu ;;
	esac
}

# --------------------------------------------------------------------------------

# 📦 System Updates

# --------------------------------------------------------------------------------

system_updates() {
	echo ">> System updating..."
	sudo dnf update -y
	echo ">> Update completed."
	read -p "Press Enter to continue..."
	main_menu
}


# ---------------------------------------------------------------------------------

# ⚙️  Ansible Configuration

# ---------------------------------------------------------------------------------

ansible_configuration() {
        clear
        sudo dnf install -y ansible-core
        clear
        echo -e "${GREEN}--- Ansible Configuration ---${NC}"

        # SSH KEY CHECK
        if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
                echo -e "${YELLOW}You don't have an SSH key pair!${NC}"
                echo -e "${YELLOW}Please generate one using: ssh-keygen${NC}"
                echo -e "${YELLOW}After generating, re-run this option.${NC}"
                read -p "Press Enter to return to the main menu..."
                main_menu
                return
        fi

        read -p "Enter the target server IP address: " target_ip
        read -p "Enter the SSH username for the remote host: " ssh_user

        echo -e "${GREEN}Copying your SSH public key to the remote host...${NC}"
        ssh-copy-id ${ssh_user}@$target_ip

        # Creating Inventory File
        echo "[remote]" > inventory
        echo "$target_ip ansible_user=$ssh_user" >> inventory

        echo ""
        echo "1) Ping test (connectivity)"
        echo "2) Copy a file to remote host"
        echo "3) Install and start Apache"
        echo "4) Run a basic user-creation playbook"
        echo "0) Back to Main Menu"
        read -p "Select an Ansible operation: " ansible_choice

        case $ansible_choice in
                1)
                        ansible -i inventory all -m ping
                        ;;
                2)
                        read -p "Enter local file path to send: " local_file
                        read -p "Enter destination path on remote: " remote_path
                        ansible -i inventory all -m copy -a "src=$local_file dest=$remote_path"
                        ;;
                3)
                        ansible -i inventory all -m yum -a "name=httpd state=present"
                        ansible -i inventory all -m service -a "name=httpd state=started enabled=yes"
                        echo "Dont forget to add http for firewall"
                        ;;
                4)
                        read -p "Enter the username to create: " remote_user
                        echo -e "${GREEN}Creating and running a basic playbook...${NC}"
                        cat <<EOF > user_add.yml
---
- name: Create a new user on remote host
  hosts: all
  become: yes
  tasks:
    - name: Ensure user '$remote_user' exists
      user:
        name: $remote_user
        state: present
EOF
                        ansible-playbook -i inventory user_add.yml
                        ;;
                0)
                        main_menu
                        return
                        ;;
                *)
                        echo -e "${RED}Invalid option!${NC}"
                        ;;
        esac

        read -p "Press Enter to return to the main menu..."
        main_menu
}


# ---------------------------------------------------------------------------------

# 🔐 Pam Security Configuration

# ---------------------------------------------------------------------------------

pam_configuration() {
        clear
        echo -e "${GREEN}--- PAM Security Configuration ---${NC}"
        echo "1) Reset all PAM rules to default (recommended before custom settings)"
        echo "2) Set minimum password length to 8"
        echo "3) Enforce password complexity (uppercase/lowercase/numbers)"
        echo "4) Lock account after 3 failed attempts"
        echo "5) Reset all faillock rules"
        echo "0) Back to Main Menu"
        read -p "Choose a PAM option: " pam_choice

        case $pam_choice in
                1)
                        echo -e "${GREEN}Resetting pwquality rules...${NC}"
                        # Reset pwquality.conf
                        sudo bash -c 'cat > /etc/security/pwquality.conf' <<EOF
minlen = 1
dcredit = 0
ucredit = 0
lcredit = 0
ocredit = 0
dictcheck = 0
EOF
                        echo "pwquality reset: minlen 6, no complexity, dictcheck off"
                        ;;
                2)
                        echo -e "${GREEN}Setting minimum password length to 8...${NC}"
                        sudo sed -i 's/^minlen *= *.*/minlen = 8/' /etc/security/pwquality.conf
                        echo "Done. (file: /etc/security/pwquality.conf)"
                        ;;
                3)
                        echo -e "${GREEN}Enforcing password complexity rules...${NC}"
                        if grep -q "pam_pwquality.so" /etc/pam.d/system-auth; then
                                sudo sed -i '/pam_pwquality.so/ s/\(pam_pwquality.so.*\)/\1 ucredit=-1 lcredit=-1 dcredit=-1/' /etc/pam.d/system-auth
                        else
                                sudo sed -i '/^password.*requisite/a password    requisite     pam_pwquality.so ucredit=-1 lcredit=-1 dcredit=-1' /etc/pam.d/system-auth
                        fi
                        echo "Rules set: at least 1 uppercase, 1 lowercase, 1 digit."
                        ;;
                4)
                        echo -e "${GREEN}Enabling account lock after 3 failed logins...${NC}"
                        sudo authselect enable-feature with-faillock
                        sudo authselect apply-changes
                        sudo sed -i '/deny=/d' /etc/security/faillock.conf
                        echo "deny = 3" | sudo tee -a /etc/security/faillock.conf > /dev/null
                        echo "Account will lock after 3 failed attempts."
                        ;;
                5)
                        echo -e "${GREEN}Resetting all faillock rules...${NC}"
                        sudo faillock --reset
                        echo "Faillock records reset."
                        ;;
                0)
                        main_menu
                        return
                        ;;
        esac

        read -p "Press Enter to return to the main menu..."
        main_menu
}


# ---------------------------------------------------------------------------------

# 🛡️ Security Hardening

# ---------------------------------------------------------------------------------

security_hardening() {
	clear
	echo -e "${GREEN}--- Security Hardening ---${NC}"
	echo "1) Change SSH port (requires root)"
	echo "2) Disable SSH root login"
	echo "3) Set password expiration policy (chage)"
	echo "4) Prevent root password change via GRUB (add GRUB password)"
	echo "5) Enforce SELinux and check status"
	echo "6) Firewall control"
	echo "7) Manage SELinux ports and file contexts"
	echo "8) View security logs"
	echo "9) Check sudo privileges"
	echo "10) Back to Main Menu"
	echo ""
	read -p "Choose a security option: " sec_choice

	case $sec_choice in
		1)
			read -p "Enter new SSH port (e.g. 8467): " ssh_port
			sudo semanage port -a -t ssh_port_t -p tcp "$ssh_port" 2>/dev/null || \
			sudo semanage port -m -t ssh_port_t -p tcp "$ssh_port"
                        sudo sed -i "/^Port /d" /etc/ssh/sshd_config
                        echo "Port $ssh_port" | sudo tee -a /etc/ssh/sshd_config > /dev/null
                        sudo systemctl restart sshd
                        echo -e "${GREEN}SSH port changed to $ssh_port and service restarted.${NC}"
			;;
		2)
			sudo sed -i '/^PermitRootLogin/s/ .*/ no/; /^#PermitRootLogin/s/^#.*$/PermitRootLogin no/' /etc/ssh/sshd_config
                        grep -q '^PermitRootLogin' /etc/ssh/sshd_config || echo 'PermitRootLogin no' | sudo tee -a /etc/ssh/sshd_config > /dev/null
                        sudo systemctl restart sshd
                        echo -e "${GREEN}SSH root login disabled.${NC}"
                        ;;
		3)
			read -p "Enter username to apply password aging policy to: " user
                        read -p "Enter maximum password age in days (e.g. 90): " max_age
                        read -p "Enter minimum password age in days (e.g. 8): " min_age
                        read -p "Enter warning period before expiry in days (e.g. 7): " warn_days
                        sudo chage -M "$max_age" -m "$min_age" -W "$warn_days" "$user"
                        echo -e "${GREEN}Password policy set for $user: max age $max_age, min age $min_age, warning $warn_days days.${NC}"
                        ;;
		4)
			echo -e "${GREEN}Setting GRUB password...${NC}"
			read -p "Enter new GRUB username: " grub_user
			read -s -p "Enter password: " grub_pass
			echo
			sudo grub2-mkpasswd-pbkdf2 <<EOF | tee /tmp/grub_pass.txt
$grub_pass
$grub_pass
EOF
			hash=$(grep "grub.pbkdf2" /tmp/grub_pass.txt | awk '{print $7}')
			echo "set superusers=\"$grub_user\"" | sudo tee -a /etc/grub.d/40_custom > /dev/null
			echo "password_pbkdf2 $grub_user $hash" | sudo tee -a /etc/grub.d/40_custom > /dev/null
			sudo grub2-mkconfig -o /boot/grub2/grub.cfg
			rm -f /tmp/grub_pass.txt
			echo -e "${GREEN}GRUB password set. Root password reset from boot is now protected.${NC}"
			;;
		5)
			sudo setenforce 1
			sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
			sestatus
			echo -e "${GREEN}SELinux is now in enforcing mode.${NC}"
			;;
		6)
			echo -e "${GREEN}Active zones:${NC}"
			sudo firewall-cmd --get-active-zones
			read -p "Enter zone (e.g. public): " zone
			read -p "Enter port to open (e.g. 443/tcp or 'none' to skip): " port
			if [[ "$port" != "none" ]]; then
				sudo firewall-cmd --zone=$zone --add-port=$port --permanent
				sudo firewall-cmd --reload
				echo -e "${GREEN}Port $port added to $zone.${NC}"
			fi
			;;
		7)
			echo -e "${GREEN}SELinux Configuration (via semanage)${NC}"
			echo "Note: To use semanage commands, policycoreutils-python-utils (or policycoreutils-python in older versions) must be installed on the system."
			echo "1) Add allowed HTTP port"
			echo "2) Label a custom file/directory"
			echo "3) List allowed ports"
			echo "4) List file contexts"
			read -p "Select option: " semanage_choice

			case $semanage_choice in
				1)
					read -p "Enter TCP port for HTTP (e.g. 8081): " new_port
					sudo semanage port -a -t http_port_t -p tcp $new_port
					sudo firewall-cmd --add-port=${new_port}/tcp --permanent
					sudo firewall-cmd --reload
					echo -e "${GREEN}HTTP access allowed on port $new_port.${NC}"
					;;
				2)
					read -p "Enter full path to directory or file: " path
					read -p "Enter SELinux type (e.g. httpd_sys_content_t): " sel_type
					sudo semanage fcontext -a -t $sel_type "$path"
					sudo restorecon -Rv "$path"
					echo -e "${GREEN}SELinux context set for $path.${NC}"
					;;
				3)
					sudo semanage port -l | grep http
					;;
				4)
					sudo semanage fcontext -l | less
					;;
				*)
					echo -e "${RED}Invalid option.${NC}"
					;;
			esac
			;;
		8)
			echo -e "${GREEN}Showing recent security log entries...${NC}"
			if [ -f /var/log/auth.log ]; then
				sudo tail -n 30 /var/log/auth.log
			else
				sudo tail -n 30 /var/log/secure
			fi
			;;
		9)
			echo -e "${GREEN}Listing sudo privileges...${NC}"
			sudo grep -E '^[^#]' /etc/sudoers /etc/sudoers.d/* 2>/dev/null
			;;

		10)
			main_menu
			return
			;;
		*)
			echo -e "${RED}Invalid option!${NC}"
			;;
	esac

	read -p "Press Enter to return to the main menu..."
	main_menu
}

# ---------------------------------------------------------------------------------

# 🌐 Network Configuration

# ---------------------------------------------------------------------------------

network_config() {
	clear
	echo -e "${GREEN}--- Network Configuration ---${NC}"
	nmcli device status
	read -p "Enter interface name (e.g. enp0s3): " iface
	read -p "Set static IP? (yes/no): " set_static

	if [[ "$set_static" == "yes" ]]; then
		read -p "Enter static IP (e.g. 192.168.1.100/24): " ip_addr
		read -p "Enter gateway (e.g. 192.168.1.1): " gw
		read -p "Enter DNS (e.g. 8.8.8.8): " dns

		sudo nmcli con mod "$iface" ipv4.addresses "$ip_addr"
		sudo nmcli con mod "$iface" ipv4.gateway "$gw"
		sudo nmcli con mod "$iface" ipv4.dns "$dns"
		sudo nmcli con mod "$iface" ipv4.method manual
	else
		sudo nmcli con mod "$iface" ipv4.method auto
	fi

	sudo  nmcli con down "$iface" && sudo nmcli con up "$iface"
	echo -e "${GREEN}Network settings applied.${NC}"
	read -p "Press Enter to continue..."
	main_menu
}

# ---------------------------------------------------------------------------------

# 📡 NFS & AutoFS Configuration

# ---------------------------------------------------------------------------------

nfs_autofs_setup() {
	clear
	echo -e "${GREEN}--- NFS & AutoFS Configuration ---${NC}"
	echo "1) Setup NFS Server"
	echo "2) Setup AutoFS on client"
	read -p "Choose option: " nfs_choice

	case $nfs_choice in
		1)
			read -p "Enter directory to share (e.g. /shared): " nfs_dir
			read -p "Enter your ip with 0 (e.g. 192.168.234.0/24): " nfs_ip
			sudo dnf install -y nfs-utils
			sudo mkdir "$nfs_dir"
			sudo chmod 777 "$nfs_dir"
			sudo chown nobody:nobody "$nfs_dir"
			echo "$nfs_dir $nfs_ip(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
			sudo exportfs -r
			sudo systemctl enable nfs-server
			sudo systemctl start nfs-server
			sudo firewall-cmd --add-service=nfs --permanent
			sudo firewall-cmd --reload
			echo -e "${GREEN}NFS server is ready and sharing $nfs_dir.${NC}"
			;;
		2)
			read -p "Enter NFS server IP: " nfs_server_ip
			read -p "Enter the shared file on server (without "/" e.g. shared): " mount_point
			read -p "Enter the shared file on server (with "/" e.g. /shared): " mount_point2
			sudo dnf install autofs nfs-utils -y
			echo "/mnt/nfs /etc/auto.nfs" | sudo tee -a /etc/auto.master
			sudo touch /etc/auto.nfs
			echo "$mount_point -rw,soft,intr $nfs_server_ip:$mount_point2" | sudo tee -a /etc/auto.nfs
			sudo systemctl enable autofs
			sudo systemctl start autofs
			echo -e "${RED}AutoFS configured.Dont forget to write ls /mnt/nfs/<mount_point>"
			;;
		*)
			echo -e "${RED}Invalid option${NC}"
			;;
	esac

	read -p "Press Enter to return..."
	main_menu
}

# ---------------------------------------------------------------------------------

# 💽 LVM Creation

# ---------------------------------------------------------------------------------

create_lvm() {
	clear
	echo -e "${GREEN}--- LVM Creation ---${NC}"
	echo -e "${RED}WARNING: Make sure the disk you choose is unmounted and has no important data!${NC}"
	echo -e "You must manually create a Linux partition (type 8e) using fdisk or parted before using this script."
	read -p "Do you want to continue? (y/n): " confirm
	[[ "$confirm" != "y" ]] && main_menu

	lsblk
	read -p "Enter the full path of partition (e.g. /dev/sdb1): " part
	read -p "Enter volume group name (e.g. vgdata): " vgname
	read -p "Enter logical volume name (e.g. lvdata): " lvname
	read -p "Enter size (e.g. 5G): " lvsize
	read -p "Enter mount point (e.g. /mnt/data): " mountpoint

	sudo pvcreate "$part"
	sudo vgcreate "$vgname" "$part"
	sudo lvcreate -L "$lvsize" -n "$lvname" "$vgname"
	sudo mkfs.xfs "/dev/$vgname/$lvname"
	sudo mkdir -p "$mountpoint"
	echo "/dev/$vgname/$lvname $mountpoint xfs defaults 0 0" | sudo tee -a /etc/fstab
	sudo mount -a

	echo -e "${GREEN}LVM setup complete and mounted at $mountpoint.${NC}"
	read -p "Press Enter to return to menu..."
	main_menu
}

# ---------------------------------------------------------------------------------

# 💾 Backup & Snapshot Tool

# ---------------------------------------------------------------------------------

backup_tool() {
	clear
	echo -e "${GREEN}--- Backup & Snapshot Tool ---${NC}"
	echo "1) Backup a directory (rsync)"
	echo "2) Create compressed archive (tar.gz)"
	read -p "Choose an option: " backup_choice

	case $backup_choice in
		1)
			read -p "Enter source directory: " src
			read -p "Enter backup destination: " dest
			sudo rsync -avh "$src" "$dest"
			echo -e "${GREEN}Backup completed using rsync.${NC}"
			;;
		2)
			read -p "Enter directory to compress: " dir
			read -p "Enter archive name (e.g. backup.tar.gz): " archive
			sudo tar -czvf "$archive" "$dir"
			echo -e "${GREEN}Archive $archive created.${NC}"
			;;
		*)
			echo -e "${RED}Invalid option.${NC}"
			;;
	esac

	read -p "Press Enter to return to menu..."
	main_menu
}

# ---------------------------------------------------------------------------------

# ⏰ Automation & Log Management

# ---------------------------------------------------------------------------------

automation_menu() {
	clear
	echo -e "${GREEN}--- Automation & Log Management ---${NC}"
	echo "1) Create a cron job"
	echo "2) View current cron jobs"
	echo "3) Setup log rotation for a custom log file"
	read -p "Choose an option: " auto_choice

	case $auto_choice in
		1)
			read -p "Enter script path to schedule: " script
			read -p "Enter schedule (e.g. '0 2 * * *' for daily at 2AM): " schedule
			(crontab -l 2>/dev/null; echo "$schedule bash $script") | crontab -
			echo -e "${GREEN}Cron job added.${NC}"
			;;
		2)
			echo -e "${GREEN}Your current cron jobs:${NC}"
			crontab -l
			;;
		3)
			read -p "Enter full path of the log file: " logfile
			read -p "Enter rotation frequency (daily, weekly, monthly): " freq
			read -p "How many rotations to keep? " count
			conf="/etc/logrotate.d/custom_$(basename $logfile)"
			sudo bash -c "cat > $conf" <<EOF
$logfile {
    $freq
    rotate $count
    compress
    missingok
    notifempty
}
EOF
			echo -e "${GREEN}Logrotate configuration created at $conf.${NC}"
			;;
		*)
			echo -e "${RED}Invalid option.${NC}"
			;;
	esac

	read -p "Press Enter to return to menu..."
	main_menu
}

# === End of Script ===
main_menu
