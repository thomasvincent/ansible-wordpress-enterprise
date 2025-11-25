#!/bin/bash

# WordPress Installation Test Script
set -e

echo "=== WordPress Enterprise Installation Test ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "test-docker.yml" ]; then
    print_error "test-docker.yml not found. Please run from the correct directory."
    exit 1
fi

# Check if MySQL and Redis are running
print_status "Checking external services..."
if ! docker exec wordpress-mysql mysql -uroot -proot -e "SELECT 1;" > /dev/null 2>&1; then
    print_error "MySQL is not accessible"
    exit 1
fi

if ! docker exec wordpress-redis redis-cli ping > /dev/null 2>&1; then
    print_error "Redis is not accessible"
    exit 1
fi

print_status "External services are running correctly"

# Create a test container
print_status "Creating test container..."
docker run -d --name wordpress-test-installer \
  --network wordpress-network \
  --privileged \
  -v $(pwd):/workspace \
  -w /workspace \
  ubuntu:22.04 \
  sleep infinity

# Install dependencies in the container
print_status "Installing dependencies..."
docker exec wordpress-test-installer bash -c "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update > /dev/null 2>&1
  apt-get install -y \
    python3 python3-pip sudo systemd curl wget \
    ca-certificates apt-transport-https gnupg2 \
    software-properties-common lsb-release \
    > /dev/null 2>&1
  python3 -m pip install ansible --break-system-packages > /dev/null 2>&1
  ansible-galaxy collection install \
    community.general community.mysql ansible.posix \
    > /dev/null 2>&1
"

# Run the WordPress installation
print_status "Running WordPress installation..."
docker exec wordpress-test-installer bash -c "
  export ANSIBLE_HOST_KEY_CHECKING=False
  ansible-playbook test-docker.yml --connection=local -v
" || {
  print_error "Ansible playbook failed"
  docker rm -f wordpress-test-installer
  exit 1
}

# Check if WordPress is installed
print_status "Verifying WordPress installation..."
if docker exec wordpress-test-installer bash -c "[ -f /var/www/wordpress/wp-config.php ]"; then
    print_status "WordPress configuration file found!"
else
    print_warning "WordPress configuration file not found"
fi

# Check if web server is running
if docker exec wordpress-test-installer bash -c "systemctl is-active nginx > /dev/null 2>&1"; then
    print_status "Nginx is running!"
else
    print_warning "Nginx is not running"
fi

# Test database connectivity
print_status "Testing database connectivity from WordPress container..."
docker exec wordpress-test-installer bash -c "
  mysql -hmysql -uwordpress -pwordpress -e 'SELECT 1;' wordpress
" && print_status "Database connection successful!" || print_warning "Database connection failed"

# Clean up
print_status "Cleaning up test container..."
docker rm -f wordpress-test-installer

print_status "WordPress installation test completed!"
echo ""
echo "To access the site:"
echo "- Start a new container with ports exposed:"
echo "  docker run -d --name wordpress-live --network wordpress-network -p 8080:80 wordpress-ansible:dev"
echo ""