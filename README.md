# Linuzy 

**Linuzy** is a modular, interactive Bash-based Linux system administration toolkit designed to assist both junior and senior Linux sysadmins in automating and managing routine tasks efficiently.

Created by **Enes K.**, this tool is part of a professional development project aimed at system automation, configuration, and security hardening.

Note: This tool requires root (or sudo) privileges for most modules.

---

## 📋 Features

- 📦 **System Updates** — Keep your system up to date using dnf/yum.
- ⚙️ **Ansible Integration** — Launch playbooks, configure inventory, automate setups.
- 🔐 **PAM Security Enhancer** — Enforce password complexity rules.
- 🛡️ **Security Hardening** — Configure SSH, SELinux, GRUB protections.
- 🌐 **Network Manager (nmcli)** — Manage network interfaces.
- 📡 **NFS & AutoFS Setup** — Auto-mount network shares.
- 💽 **LVM Toolkit** — Create and manage Logical Volumes.
- 💾 **Backup & Snapshot** — Simple rsync-based backups.
- ⏰ **Cron & Logrotate** — Automate jobs and manage log rotation.

---

## 🔧 Requirements

- Bash Shell
- `dnf` or `yum` based distro (Tested on RHEL/CentOS/Fedora)
- Some modules require:
  - `ansible`
  - `policycoreutils-python-utils`
  - `nfs-utils`, `autofs`
  - `lvm2`
  - `logrotate`

---

## 🚀 How to Run

chmod +x linuzy.sh
./linuzy.sh

