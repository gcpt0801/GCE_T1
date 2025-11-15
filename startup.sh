#!/bin/bash
set -e

# Apache2 is already installed via Packer image
# This script just ensures it's running and can be used for custom configuration

# Start Apache2 service (already enabled in Packer)
systemctl start apache2

# Optional: Add your custom website content here
# Example: Copy custom index.html, configure virtual hosts, etc.
echo "Apache2 startup complete"