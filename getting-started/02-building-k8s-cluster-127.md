# Building a Kubernetes 1.27 Cluster with kubeadm 
This document runs through how to setup a Kubernetes Cluster using Kubeadm running on Ubuntu 20.04. See notes from [01-prepping-cloud-playground.md](./01-prepping-cloud-playground.md) for setting up the servers. 

> I have created a script to automate this process. See 02-setup-script.sh

## Installing packages  
1. Using ssh onto each server:  `ssh cloud_user@<IP_ADDRESS>` the supply your password. 
2. Install conatinerd runtime on each server
    a. Instruct the server to load the overlay and br_netfilter modules on startup (modules are required by containerd)
    ```sh
    cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
    overlay
    br_netfilter
    EOF
    ```
    b. Ensure modules are loaded imediately without needing to restart the server
    ```sh
    sudo modprobe overlay
    sudo modprobe br_netfilter
    ```
    c. Set system level config needed for kubernetes networking
    ```sh
    cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    EOF
    sudo sysctl --system
    ```
    d. Install containerd package
    ```sh
    sudo apt-get update && sudo apt-get install -y containerd
    ```
    e. Setup containerd configuration
    ```sh
    sudo mkdir -p /etc/containerd 
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    ```
    f. Check that containerd is running and using the config 
    ```sh 
    sudo systemctl restart containerd 
    sudo systemctl status containerd
    ```
3. Install Kubernetes Packages [link](https://v1-27.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)
    a. disable swap: `sudo swapoff -a`
    b. install pre-reqs `sudo apt-get update && sudo apt-get install -y apt-transport-https curl`
    c. download the public signing key for the k8s package repos `curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg`
    d. Setup repo configuration `echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list`
    e. Update the apt package index and install k8s tools and hold k8s tools version. 
    ```sh
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```

## Initialise the cluster (Controller Only)
1. On the control plane only, initialise the cluster setting the pod networkd cidr and k8s version to use: `sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.27.11`
2. configure kubectl to communicate with the server. Note, this is the output from the previous command
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
3. Confirm node is installed, don't worry about the status: `kubectl get nodes`

## Install the Calico Network Add-On (Controller Only)
1. Install the Calico Network Add-On on the control server only: `kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml`
2. Wait for a few minutes and check that the control node is in the ready status: `kubectl get nodes`
## Join Worker Nodes to the Cluster 
1. Obtain the join tokens from the control server: `kubeadm token create --print-join-command`
2. Copy the output from the above command and run it on the worker nodes. Remember to add sudo before the command. It should look something like this: `sudo kubeadm join [CONTROL_NODE_IP]:6443 --token [TOKEN] --discovery-token-ca-cert-hash sha256:[SHA_KEY]`
3. On the control server check that the nodes are ready: `kubectl get nodes`