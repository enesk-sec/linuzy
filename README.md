# Linuzy 

**Linuzy** is a modular, interactive Bash-based Linux system administration toolkit designed to assist both junior and senior Linux sysadmins in automating and managing routine tasks efficiently.

Created by **Enes K.**, this tool is part of a professional development project aimed at system automation, configuration, and security hardening.

Note: This tool requires root (or sudo) privileges for most modules.

---

## 📋 Features

- 📦 System Updates
- ⚙️  Ansible Playbook Launcher (with target IP configuration)
- 🔐 PAM Security Enhancer (password complexity policies)
- 🛡️ Security Hardening (SSH, SELinux, GRUB, chage, etc.)
- 🌐 Network Management with `nmcli`
- 📡 NFS + AutoFS Setup
- 💽 LVM Creation from a new disk
- 💾 Backup & Snapshot Tool
- ⏰ Cron Automation + Logrotate Config

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

