#!/bin/bash

# Set error handling
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting Helm installation..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Working in temporary directory: $TEMP_DIR"

# Clone Helm repository
echo "Cloning Helm repository..."
git clone https://github.com/helm/helm.git "$TEMP_DIR/helm"
cd "$TEMP_DIR/helm"

# Build Helm
echo "Building Helm..."
make

# Check if build was successful
if [ ! -f "bin/helm" ]; then
    echo "Error: Helm build failed"
    exit 1
fi

# Move binary to system path
echo "Moving Helm binary to /usr/local/bin..."
sudo mv bin/helm /usr/local/bin/

# Verify installation
if ! command_exists helm; then
    echo "Error: Helm installation failed"
    exit 1
fi

# Display version
echo "Helm installed successfully!"
helm version

# Cleanup
echo "Cleaning up..."
cd
rm -rf "$TEMP_DIR"

echo "Installation complete!"
