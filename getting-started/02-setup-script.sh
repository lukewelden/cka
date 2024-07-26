#!/bin/bash

set -e

# Function to handle errors
error_handler() {
    echo "Error occurred in script at line: ${1}. Exiting."
    exit 1
}

# Trap errors and call the error_handler function
trap 'error_handler $LINENO' ERR

#############################################
# Install containerd runtime on each server #
#############################################

# Instruct the server to load the overlay and br_netfilter modules on startup
echo "Loading overlay and br_netfilter modules on startup..."
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Ensure modules are loaded immediately without needing to restart the server
echo "Loading overlay and br_netfilter modules immediately..."
sudo modprobe overlay
sudo modprobe br_netfilter

# Set system level config needed for kubernetes networking
echo "Setting system level config for Kubernetes networking..."
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

# Install containerd package
echo "Installing containerd package..."
sudo apt-get update
sudo apt-get install -y containerd

# Setup containerd configuration
echo "Setting up containerd configuration..."
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Check that containerd is running and using the config
echo "Restarting and checking containerd service..."
sudo systemctl restart containerd
sudo systemctl status containerd

echo "Containerd setup completed successfully."

###############################
# Install Kubernetes Packages # 
###############################

# Disable swap
echo "Disabling swap..."
sudo swapoff -a

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y apt-transport-https curl

# Download the public signing key for the k8s package repos
echo "Downloading public signing key for Kubernetes package repositories..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Setup repository configuration
echo "Setting up Kubernetes repository configuration..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the apt package index and install Kubernetes tools
echo "Updating apt package index and installing Kubernetes tools..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Script completed successfully."