#!/bin/bash
set -e

# Define variables
DOTNET_INSTALL_SCRIPT_URL="https://dot.net/v1/dotnet-install.sh"
DOTNET_DIR="./.dotnet"

# cleanup function
cleanup() {
    rm -f dotnet-install.sh
}

# Trap exit to ensure cleanup
trap cleanup EXIT

# Download dotnet-install script
echo "Downloading dotnet-install.sh..."
curl -sSL "$DOTNET_INSTALL_SCRIPT_URL" -o dotnet-install.sh
chmod +x dotnet-install.sh

# Install .NET SDK 8.0
echo "Installing .NET SDK 8.0..."
./dotnet-install.sh --channel 8.0 --install-dir "$DOTNET_DIR" --no-path

# Setup environment variables
export DOTNET_ROOT="$(pwd)/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

# Verify installation
dotnet --version

# Run the build
echo "Building SoftScroll..."
# The build command as specified in README
dotnet publish -p:PublishProfile=Properties/PublishProfiles/SoftScrollSingleFile.pubxml

echo "Build complete."
