# Update the apt package
set -e
echo "Updating apt package index..."
sudo apt-get update

echo "Installing apt-transport-https, ca-certificates, curl, gpg..."
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Download Public Signing Key 
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
echo "Downloading Kubernetes public signing key..."
sudo mkdir -p -m 755 /etc/apt/keyrings || true
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add K8s apt repo
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo "Adding Kubernetes apt repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt package index, install kube tools and pin their version
echo "Updating apt package index, installing kube tools and pinning their version..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service 
echo "Enabling kubelet service..."
sudo systemctl enable --now kubelet