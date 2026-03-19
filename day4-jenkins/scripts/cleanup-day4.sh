#!/bin/bash
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Day 4: Jenkins Cleanup${NC}"
echo ""

echo "Stopping Jenkins..."
sudo systemctl stop jenkins 2>/dev/null || true

echo "Stopping Docker containers..."
docker-compose -f "$(dirname "$0")/../docker/docker-compose.yml" down 2>/dev/null || true

echo -e "${GREEN}Day 4 cleanup complete.${NC}"
echo "Note: To fully remove Jenkins EC2 instance, use Terraform destroy from Day 2."
