#!/bin/bash
# =============================================================================
# Jenkins Installation Script for Amazon Linux 2
# =============================================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Installing Jenkins on Amazon Linux 2${NC}"

# Install Java 11
echo -e "${YELLOW}Installing Java 11...${NC}"
sudo amazon-linux-extras install java-openjdk11 -y

# Add Jenkins repo
echo -e "${YELLOW}Adding Jenkins repository...${NC}"
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
echo -e "${YELLOW}Installing Jenkins...${NC}"
sudo yum install jenkins -y

# Install Git, Docker
sudo yum install git docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker jenkins

# Start Jenkins
echo -e "${YELLOW}Starting Jenkins...${NC}"
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Wait for Jenkins to start
sleep 30

# Display initial password
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Jenkins installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
