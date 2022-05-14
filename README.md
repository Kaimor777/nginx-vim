

# Test project for Tikal

Test project for Tikal company to apply for DevOps position.

## Requirements

 - Kubernetes cluster
 - GitHub public repository public access
 - DockerHub repository (public or private)
 - CI\\CD pipeline
## Setup

### Environment

Virtualization platform [Oracle VirtualBox 6.1](https://www.virtualbox.org/wiki/Downloads)
OS: **Ubuntu 20.04**

### K8S

Kubernetes cluster setup:
 - 1 Master Node
 - 2 Worker Nodes
 - Container runtime: containerd
 - CNI: Flannel


#### Installation

Create 3 virtual machines:
 Master Node: 2 CPU 2GB RAM 10 GB VHD 1 NIC
  NIC connected to **NAT network**
 Worker Node: 4 CPU 4 GB RAM 10 GB VHD 1 NIC
  NIC connected to **NAT network**

Install Ubuntu 20.04 LTS Server following [installation procedure](https://linuxhint.com/install_ubuntu_virtualbox_2004/)

Login to created machines and change IP addresses to static
Create new YAML configuration file for ***netplan*** service
```bash
sudo vim /etc/netplan/01-network.yaml
```
Add static IP configuration including default route and DNS servers

Restart netplan service

Change hostname on all machines to unique one

Disable swap

```bash
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
```

Load modules to truntime

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Configure persistent loading of modules

```bash
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
```

Ensure sysctl params are set

```bash
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

Reload config

```bash
sudo sysctl --system
```

Install required packages

```bash
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
```

Add Docker repo
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

Install containerd
```bash
sudo apt update
sudo apt install -y containerd.io
```

Configure containerd and start service
```bash
sudo su -
mkdir -p /etc/containerd
containerd config default>/etc/containerd/config.toml
```

Restart containerd

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
systemctl status  containerd
```

Install Kubernetes and dependencies
```bash
sudo apt -y install curl apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt -y install vim git curl wget kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
