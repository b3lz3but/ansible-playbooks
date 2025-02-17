# Ansible Playbooks for DevOps Daily Operations

## 📌 Overview

This repository contains a collection of **Ansible playbooks** to automate essential **DevOps** tasks, including:

- **System Administration** (User management, package updates, kernel upgrades, file system maintenance)
- **Networking** (Firewall rules, DNS settings, load balancing, VPN configurations)
- **Scripting & Automation** (Using Bash, Python, Ansible scripts)
- **Monitoring & Logging** (Setup Prometheus, ELK stack, Splunk, log analysis)
- **Security & Compliance** (System hardening, intrusion detection, access control)
- **Troubleshooting** (System performance diagnostics, error checking)
- **Cloud Management** (AWS, Azure, GCP automation)
- **Containerization** (Docker, Kubernetes orchestration)
- **CI/CD Pipelines** (Jenkins, GitLab CI, automated deployments)
- **Database Administration** (MySQL backups, restores, performance tuning)
- **Documentation & Collaboration** (Maintaining system knowledge bases, version control)

## 📂 Project Structure

```
ansible-playbooks/
│── inventory.ini             # Inventory file (defines target hosts)
│── ansible.cfg               # Configuration settings for Ansible
│── playbooks/                # Directory containing playbooks
│   ├── update_packages.yml
│   ├── restart_services.yml
│   ├── check_disk_space.yml
│   ├── system_health_monitor.yml
│   ├── security_scan.yml
│   ├── backup_files.yml
│   ├── user_management.yml
│   ├── log_cleanup.yml
│   ├── network_check.yml
│   ├── system_administration.yml
│   ├── networking.yml
│   ├── scripting_automation.yml
│   ├── monitoring_logging.yml
│   ├── security_hardening.yml
│   ├── troubleshooting.yml
│   ├── cloud_management.yml
│   ├── containerization.yml
│   ├── ci_cd.yml
│   ├── database_admin.yml
│   ├── documentation.yml
│   ├── collaboration.yml
│── roles/                    # Ansible roles (if applicable)
│── templates/                 # Jinja2 templates (if any)
│── files/                      # Static files (e.g., SSH keys, scripts)
```

## 🚀 How to Use

### 1️⃣ Install Ansible
Ensure you have Ansible installed on your control machine (you can also install it via `pip`):
```sh
sudo apt update && sudo apt install ansible -y  # Debian/Ubuntu
sudo yum install ansible -y                     # CentOS/RHEL
brew install ansible                             # macOS
```

### 2️⃣ Configure Inventory File (`inventory.ini`)
Edit the `inventory.ini` file and add your servers. Example:
```
[servers]
server1 ansible_host=192.168.1.100 ansible_user=root
server2 ansible_host=192.168.1.101 ansible_user=root

[database_servers]
db1 ansible_host=192.168.1.200 ansible_user=root
```

### 3️⃣ Run a Playbook
Execute a playbook to perform an automated task. Example:
```sh
ansible-playbook -i inventory.ini playbooks/update_packages.yml
```

### 4️⃣ Run a Playbook on a Specific Host
```sh
ansible-playbook -i inventory.ini -l server1 playbooks/restart_services.yml
```

### 5️⃣ Running Playbooks with Extra Variables
```sh
ansible-playbook -i inventory.ini playbooks/user_management.yml --extra-vars "user_name=devops"
```

## 📜 Description of Playbooks

| Playbook                    | Description                                                    |
| --------------------------- | -------------------------------------------------------------- |
| `update_packages.yml`       | Updates system packages on remote machines (APT/YUM)           |
| `restart_services.yml`      | Restarts Nginx, Apache, and MySQL services                     |
| `check_disk_space.yml`      | Checks disk space usage on target hosts                        |
| `system_health_monitor.yml` | Monitors CPU, memory, and uptime                               |
| `security_scan.yml`         | Runs ClamAV security scans and checks open ports               |
| `backup_files.yml`          | Backs up `/etc` configuration files                            |
| `user_management.yml`       | Creates users and sets SSH authentication                      |
| `log_cleanup.yml`           | Cleans up old log files older than 30 days                     |
| `network_check.yml`         | Checks network connectivity (ping test)                        |
| `system_administration.yml` | Handles kernel updates, user management, and file system tasks |
| `networking.yml`            | Configures firewall, network interfaces, and DNS settings      |
| `scripting_automation.yml`  | Automates basic tasks with Bash/Python scripts                 |
| `monitoring_logging.yml`    | Sets up Prometheus monitoring & ELK stack                      |
| `security_hardening.yml`    | Ensures SELinux, AppArmor, and security policies               |
| `troubleshooting.yml`       | Collects system logs and error messages                        |
| `cloud_management.yml`      | Manages AWS/Azure/GCP resources                                |
| `containerization.yml`      | Installs Docker, Kubernetes, and related tools                 |
| `ci_cd.yml`                 | Installs Jenkins and sets up CI/CD pipelines                   |
| `database_admin.yml`        | Automates MySQL backups and restores                           |
| `documentation.yml`         | Maintains system documentation and logs                        |
| `collaboration.yml`         | Ensures Git installation and version control                   |

## 🔥 Useful Ansible Commands

- **Test Ansible connectivity**:
  ```sh
  ansible -i inventory.ini all -m ping
  ```

- **Run ad-hoc command** (Get uptime of all servers):
  ```sh
  ansible -i inventory.ini all -m command -a "uptime"
  ```

- **List available hosts in inventory**:
  ```sh
  ansible-inventory -i inventory.ini --list
  ```

## 🎯 Best Practices

✔️ Always **test** playbooks in a staging environment before running in production.<br>
✔️ Use **roles** to organize playbooks for larger projects.<br>
✔️ Implement **Ansible Vault** for storing sensitive credentials securely.<br>
✔️ Use **tags** for running specific tasks within a playbook.<br>
✔️ Schedule **cron jobs** to run playbooks automatically for maintenance tasks.<br>

## 📢 Contribution

If you have suggestions for improvement or new playbooks, feel free to contribute by submitting a pull request.

## 📞 Support

For any questions or issues, reach out to the DevOps team or check the [Ansible Documentation](https://docs.ansible.com/).

---

🔨 **Built for automation, efficiency, and reliability!** 🚀
