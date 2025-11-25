#!/bin/bash

set -e

echo "=== Simple WordPress Installation Test ==="

# Check external services
if ! docker exec wordpress-mysql mysql -uroot -proot -e "SELECT 1;" > /dev/null 2>&1; then
    echo "ERROR: MySQL is not accessible"
    exit 1
fi

echo "✓ External services are running"

# Create test container
echo "Creating test container..."
docker run -d --name wp-simple-test \
  --network wordpress-network \
  --privileged \
  -v $(pwd):/workspace \
  -w /workspace \
  ubuntu:22.04 \
  sleep infinity

# Install minimal dependencies
echo "Installing dependencies..."
docker exec wp-simple-test bash -c "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update > /dev/null
  apt-get install -y python3 python3-pip sudo > /dev/null
  python3 -m pip install ansible > /dev/null 2>&1 || pip3 install ansible > /dev/null 2>&1
  ansible-galaxy collection install community.general community.mysql ansible.posix > /dev/null
"

# Run simple test
echo "Running WordPress installation..."
docker exec wp-simple-test bash -c "
  export ANSIBLE_HOST_KEY_CHECKING=False
  ansible-playbook simple-test.yml --connection=local
" && echo "✓ Installation successful!" || echo "✗ Installation failed"

# Cleanup
echo "Cleaning up..."
docker rm -f wp-simple-test

echo "Test completed!"