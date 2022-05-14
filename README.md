

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

#### Installation

Create 3 virtual machines:
 Master Node: 2 CPU 2GB RAM 10 GB VHD 1 NIC
  NIC connected to **NAT network**
 Worker Node: 4 CPU 4 GB RAM 10 GB VHD 1 NIC
  NIC connected to **NAT network**

Install Ubuntu 20.04 LTS Server following [installation procedure](https://linuxhint.com/install_ubuntu_virtualbox_2004/)

Login to created machines and change IP addresses to static
```bash
sudo vim /etc/netplan/01-network.yaml
```
