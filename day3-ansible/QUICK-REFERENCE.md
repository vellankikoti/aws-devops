# Day 3: Ansible Quick Reference

## Core Commands

| Command | Description |
|---------|-------------|
| `ansible all -m ping` | Test connectivity |
| `ansible all -m setup` | Gather all facts |
| `ansible-playbook site.yml` | Run master playbook |
| `ansible-playbook site.yml --check` | Dry run |
| `ansible-playbook site.yml --diff` | Show changes |
| `ansible-playbook site.yml --tags docker` | Run specific tags |
| `ansible-playbook site.yml --limit web1` | Target specific host |
| `ansible-playbook site.yml -v` | Verbose output |
| `ansible-vault create secrets.yml` | Create encrypted file |
| `ansible-vault edit secrets.yml` | Edit encrypted file |
| `ansible-galaxy init myrole` | Create role scaffold |

## Ad-Hoc Commands

```bash
# Run command on all hosts
ansible all -m shell -a "uptime"

# Copy file
ansible webservers -m copy -a "src=file.txt dest=/tmp/"

# Install package
ansible webservers -m yum -a "name=htop state=present" -b

# Restart service
ansible webservers -m service -a "name=docker state=restarted" -b

# Check disk space
ansible all -m shell -a "df -h"
```

## Playbook Patterns

```yaml
# Conditional
- name: Install on Amazon Linux only
  yum: name=docker state=present
  when: ansible_distribution == "Amazon"

# Loop
- name: Install packages
  yum: name={{ item }} state=present
  loop: [docker, git, htop]

# Register and check
- name: Check service
  command: systemctl status docker
  register: result
  failed_when: result.rc not in [0, 3]

# Block/rescue
- block:
    - name: Try deploy
      command: docker-compose up -d
  rescue:
    - name: Rollback
      command: docker-compose down
```

## Inventory Patterns

```bash
# List hosts
ansible-inventory --list
ansible-inventory --graph

# Use dynamic inventory
ansible-playbook -i inventory/aws_ec2.yml site.yml
```
