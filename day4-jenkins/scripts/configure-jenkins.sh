#!/bin/bash
# =============================================================================
# Jenkins Post-Install Configuration
# =============================================================================
set -e

echo "Installing Jenkins CLI tools..."

# Install Terraform on Jenkins server
wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip -o terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.6.6_linux_amd64.zip

# Install Ansible
sudo pip3 install ansible boto3 botocore

# Install AWS CLI v2
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip

echo "Jenkins tools configured!"
echo "Now configure credentials in Jenkins UI:"
echo "  1. AWS Credentials (Manage Jenkins → Credentials)"
echo "  2. GitHub Token"
echo "  3. SSH Key for EC2"
