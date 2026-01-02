# Testing Guide

This document describes how to test the ansible-wordpress-enterprise role using Molecule.

## Overview

The role uses [Molecule](https://molecule.readthedocs.io/) as the testing framework with Docker as the driver. Tests are organized into multiple scenarios to ensure comprehensive coverage across different platforms and configurations.

## Prerequisites

### Required Tools

- Python 3.8 or newer
- Docker (for running test containers)
- Git

### Installation

```bash
# Install testing dependencies
pip install -r requirements.txt

# Or install individually
pip install molecule>=6.0.0
pip install molecule-plugins[docker]>=23.5.0
pip install ansible>=8.5.0
pip install ansible-lint>=6.22.0
pip install yamllint>=1.33.0
```

### Ansible Collections

```bash
ansible-galaxy collection install community.general
ansible-galaxy collection install community.mysql
ansible-galaxy collection install ansible.posix
```

## Test Scenarios

### Default Scenario

**Path:** `molecule/default/`

**Platforms:**
- Ubuntu 22.04
- Ubuntu 24.04
- Rocky Linux 9

**Purpose:** Quick testing across major supported platforms.

```bash
molecule test
# or explicitly
molecule test --scenario-name default
```

### Ubuntu Scenario

**Path:** `molecule/ubuntu/`

**Platforms:**
- Ubuntu 22.04 (Jammy)
- Ubuntu 24.04 (Noble)

**Purpose:** Ubuntu-specific testing and validation.

```bash
molecule test --scenario-name ubuntu
```

### Debian Scenario

**Path:** `molecule/debian/`

**Platforms:**
- Debian 11 (Bullseye)
- Debian 12 (Bookworm)

**Purpose:** Debian-specific testing and validation.

```bash
molecule test --scenario-name debian
```

### RHEL Scenario

**Path:** `molecule/rhel/`

**Platforms:**
- Rocky Linux 8 (RHEL 8 compatible)
- Rocky Linux 9 (RHEL 9 compatible)

**Purpose:** RHEL/CentOS/AlmaLinux-compatible testing.

```bash
molecule test --scenario-name rhel
```

## Test Sequence

Each scenario runs through the following test sequence:

1. **Dependency**: Install required Ansible Galaxy collections
2. **Cleanup**: Remove any previous test artifacts
3. **Destroy**: Tear down any existing test containers
4. **Syntax**: Validate Ansible playbook syntax
5. **Create**: Create test containers
6. **Prepare**: Prepare test containers (install Python, etc.)
7. **Converge**: Run the role against test containers
8. **Idempotence**: Verify role is idempotent (no changes on second run)
9. **Verify**: Run verification tests
10. **Cleanup**: Clean up test artifacts
11. **Destroy**: Tear down test containers

## Interactive Testing

For development and debugging, you can run individual steps:

```bash
# Create test environment
molecule create

# Run the role
molecule converge

# Run verification tests
molecule verify

# Login to a test container
molecule login --host ubuntu-22.04

# Check idempotency
molecule idempotence

# Destroy test environment
molecule destroy
```

## Running Specific Tests

### Test a Single Platform

To test only Ubuntu 22.04 from the default scenario:

```bash
# Create and converge
MOLECULE_PLATFORM=ubuntu-22 molecule converge

# Login to specific container
molecule login --host ubuntu-22
```

### Test Without Destroying

Useful for debugging:

```bash
molecule test --destroy=never
```

### Skip Specific Steps

```bash
# Skip destroy at the end
molecule test --destroy=never

# Skip idempotency check
molecule converge
molecule verify
```

## Verification Tests

Each scenario includes a `verify.yml` playbook that validates:

### Common Checks
- ✅ WordPress directory exists
- ✅ WordPress core files are present
- ✅ wp-config.php is configured
- ✅ Web server is running (Apache/Nginx)
- ✅ PHP is installed and working
- ✅ Database service is running
- ✅ Database is accessible
- ✅ WordPress database exists

### Platform-Specific Checks
- **Ubuntu/Debian**: Verifies apt packages
- **RHEL/Rocky**: Verifies rpm packages
- Service name validation (apache2 vs httpd)

## Continuous Integration

Tests run automatically on GitHub Actions for:
- All pull requests
- Pushes to main/develop branches
- Weekly scheduled runs
- Manual workflow dispatch

### CI Test Matrix

| Job | Scenario | Platform |
|-----|----------|----------|
| test-ubuntu-22 | default | Ubuntu 22.04 + Rocky 9 |
| test-ubuntu-24 | ubuntu | Ubuntu 22.04 + 24.04 |
| test-debian | debian | Debian 11 + 12 |
| test-rocky-9 | default | Ubuntu 22.04 + Rocky 9 |
| test-rhel | rhel | Rocky Linux 8 + 9 |

## Troubleshooting

### Docker Permission Issues

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Container Won't Start

```bash
# Clean up Docker resources
docker system prune -f

# Remove Molecule cache
rm -rf ~/.cache/molecule/
```

### Python Dependencies

```bash
# Reinstall dependencies
pip install --force-reinstall -r requirements.txt
```

### Debugging Failed Tests

```bash
# Run with verbose output
molecule --debug test

# Keep container running after failure
molecule test --destroy=never

# Login to inspect
molecule login --host <hostname>
```

## Writing Custom Tests

### Adding a New Scenario

1. Create scenario directory:
```bash
mkdir -p molecule/new-scenario
```

2. Add required files:
- `molecule.yml` - Scenario configuration
- `converge.yml` - Role execution playbook
- `verify.yml` - Validation tests
- `prepare.yml` - Container preparation (optional)

3. Configure platforms in `molecule.yml`:
```yaml
platforms:
  - name: test-platform
    image: ubuntu:22.04
    dockerfile: ../default/Dockerfile.j2
```

4. Run the new scenario:
```bash
molecule test --scenario-name new-scenario
```

### Adding Verification Tests

Edit `verify.yml` in your scenario:

```yaml
- name: Custom verification
  hosts: all
  tasks:
    - name: Check custom configuration
      ansible.builtin.stat:
        path: /path/to/config
      register: config_check
      failed_when: not config_check.stat.exists
```

## Performance Considerations

### Speed Up Tests

```bash
# Use fewer platforms
molecule test --platform-name ubuntu-22

# Skip dependency installation
molecule test --skip-dependency

# Parallel execution (use with caution)
molecule test --parallel
```

### Resource Usage

Each test container requires:
- **Memory**: ~512MB minimum
- **Disk**: ~2GB per container
- **CPU**: 1 core recommended per container

## Best Practices

1. **Run tests before committing**: Ensure changes don't break functionality
2. **Test on all platforms**: Don't assume behavior is consistent
3. **Keep tests fast**: Disable unnecessary features in test configs
4. **Use meaningful test names**: Make failures easy to understand
5. **Document test assumptions**: Add comments to complex test logic
6. **Clean up after testing**: Run `molecule destroy` when done

## Getting Help

- **Molecule Documentation**: https://molecule.readthedocs.io/
- **Ansible Documentation**: https://docs.ansible.com/
- **GitHub Issues**: https://github.com/thomasvincent/ansible-wordpress-enterprise/issues
- **GitHub Discussions**: https://github.com/thomasvincent/ansible-wordpress-enterprise/discussions

## Contributing Tests

We welcome test improvements! See [CONTRIBUTING.md](CONTRIBUTING.md) for details on:
- Adding new test scenarios
- Improving verification tests
- Fixing test flakiness
- Optimizing test performance
