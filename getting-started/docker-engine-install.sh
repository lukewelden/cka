#!/bin/bash

# Exit on any error
set -e

# Function to report errors
report_error() {
    echo "Error occurred in script execution. Exiting."
    exit 1
}

# Step 1: Uninstall old versions
echo "Uninstalling old versions..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

# Step 2: Setup Docker's apt repository
echo "Setting up Docker's apt repository..."
sudo apt-get update || report_error
sudo apt-get install -y ca-certificates curl || report_error
sudo install -m 0755 -d /etc/apt/keyrings || report_error
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || report_error
sudo chmod a+r /etc/apt/keyrings/docker.asc || report_error

# Add the Docker repository
echo "Adding Docker repository to apt sources..."
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || report_error

sudo apt-get update || report_error

# Step 3: Install Docker packages
echo "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || report_error

# Step 4: Install cri-dockerd
echo "Installing cri-dockerd..."
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd_0.3.15.3-0.ubuntu-focal_amd64.deb || report_error
sudo dpkg -i cri-dockerd_0.3.15.3-0.ubuntu-focal_amd64.deb || report_error
sudo apt-get install -f || report_error  # This will install any missing dependencies

# Step 5: Verify installation
echo "Verifying Docker installation..."
sudo docker run hello-world || report_error

echo "Docker and cri-dockerd installation completed successfully."