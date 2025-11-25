#!/bin/bash

# CentOS/Rocky Linux systemd init script for testing
set -e

# Start systemd in container
exec /sbin/init --log-level=info --log-target=console