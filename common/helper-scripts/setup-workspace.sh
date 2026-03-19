#!/bin/bash
set -e
echo "=== Setting Up DevOps Workspace ==="

# AWS CLI
if ! command -v aws &>/dev/null; then
  echo "Installing AWS CLI..."
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp/ && sudo /tmp/aws/install
fi

# Terraform
if ! command -v terraform &>/dev/null; then
  echo "Installing Terraform..."
  wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip -O /tmp/tf.zip
  unzip -q /tmp/tf.zip -d /tmp/ && sudo mv /tmp/terraform /usr/local/bin/
fi

# Ansible
if ! command -v ansible &>/dev/null; then
  echo "Installing Ansible..."
  pip3 install ansible boto3 botocore
fi

# kubectl
if ! command -v kubectl &>/dev/null; then
  echo "Installing kubectl..."
  curl -sLO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/
fi

# eksctl
if ! command -v eksctl &>/dev/null; then
  echo "Installing eksctl..."
  curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin/
fi

# Helm
if ! command -v helm &>/dev/null; then
  echo "Installing Helm..."
  curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo ""
echo "All tools installed! Run check-prerequisites.sh to verify."
