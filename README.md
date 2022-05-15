

# Test project for Tikal

Test project for Tikal company to apply for DevOps position.

# What it does

Custom Docker Image of *nginx* will be created on DockerHub with HTML page with Jenkins

Deployment will be done through ArgoCD

The page will be available within local environment only

# Requirements

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

##### Prepare the VM's <a name='Prepare the VM'></a>

***Following must be done on all machines***

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

##### Install K8S cluster

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

***For testing purposes only ufw must be disabled***

```bash
sudo systemctl disable ufw
sudo systemctl stop ufw
```

On ***Master*** proceed with following

***Pay attention CIDR 10.244.0.0/16 must NOT be used on any part of the network***

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

Please copy the line started with *kubeadm join*

Something like
```bash
kubeadm join 192.168.10.5:6443 --token x0n92f.fgxdjnofuk95bz81 \
        --discovery-token-ca-cert-hash sha256:33b32457478f745f671376f6987a38b1a6697574c7ed98fcab2d9139d472f8ad
```

The IP addres should be one of your Master node

Execute folowing to proceed

```shell
sudo cp /etc/kubernetes/admin.conf $HOME/
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
```

Install CNI (Flannel)

```shell
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```

*To join Worker nodes execute copied string **kubeadm join** with sudo*

And to confirm, when we do a `kubectl get nodes`, we should see something like:

```shell
NAME                            STATUS    AGE       VERSION
server1                         Ready     46m       v1.7.0
server2                         Ready     3m        v1.7.0
server3                         Ready     2m        v1.7.0
```

##### Install Metric server

```shell
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Edit file components.yaml

```shell
vim components.yaml
```

```shell
template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      hostNetwork: true
      containers:
      - args:
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --cert-dir=/tmp
```

Added lines should be set up for insecure connectivity support

*- --kubelet-insecure-tls*
*- --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname*
*hostNetwork: true*

Install metric server

```shell
kubectl apply -f components.yaml
```

##### Install Helm

On *Master* node:

```shell
curl -O https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3

bash ./get-helm-3

helm version
```

##### Add secondary NIC to Master node

Add it to host-Only network and edit netplan file to setup a static IP configuration

##### Install ArgoCD via Helm

```shell
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd
```

Follow on screen instructions to retrieve admin one time password

Expose the service with following command
```shell
kubectl port-forward service/argocd-server -n default 8090:443 --address="0.0.0.0"
```

Web UI of argoCD will be accessible through any IP of *Master* node

### CI\\CD pipeline

#### DockerHub

Create a private repository within your account named *nginx-vim*

On *Master* node

Login to docker

```shell
docker login
```

View vconfig file

```shell
cat ~/.docker/config.json
```

Create a secret for Kubernetes to authenticate

```shell
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson
```

#### GitHub

Setup a github repository with public accessible

For project purposes repository will be public

Create a subfolders named *argocd/nginx-vim-stable*

Create files
 - Dockerfile
 - index.html
 - Jenkinsfile


*Dockerfile context*

```shell
ROM nginx

RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "vim"]
COPY index.html /usr/share/nginx/html
```

*Jenkinsfile*

Jenkinsfile context

```shell
node {
    def app

    stage('Clone repository') {
        /* Let's make sure we have the repository cloned to our workspace */

        checkout scm
    }

    stage('Build image') {
        /* This builds the actual image; synonymous to
         * docker build on the command line */

        app = docker.build("YOUR_ACCOUNT_ON_DOCKERHUB/nginx-vim")
    }

    stage('Push image') {
        /* Finally, we'll push the image with two tags:
         * First, the incremental build number from Jenkins
         * Second, the 'latest' tag.
         * Pushing multiple tags is cheap, as all the layers are reused. */
        docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
            app.push("${env.BUILD_NUMBER}")
            app.push("latest")
        }
    }
}
```

PLace any HTML code to *index.html*


#### Jenkins environment

Install additional VM: Ubuntu 20.04, 1 CPU, 2GB RAM
1 NIC: host-Only network
2 NIC: NAT network

Setup static IP addresses for both NIC with appropriate network settings

Install Jenkins
```shell
sudo apt-get update

sudo apt-get install openjdk-8-jdk

wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

sudo apt-get update

sudo apt install default-jdk

sudo apt-get install jenkins

sudo apt install git
```

Retrieve initial password from installation log

```shell
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

To be able to make container image Jenkins server must have container runtime installed.

```shell
sudo apt-get install     ca-certificates     curl     gnupg     lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

To provide Jenkins availability to run docker compose add jenkins user to *docker* group

```shell
sudo usermod -aG docker jenkins
```

#### Jenkins configuration

Login to Jenkins

From Jenkins *Dashboard* -> *Manage Jenkins* -> *Manage Plugins*

Install following plugins:
 - Docker Pipeline
 - Docker Plugin
 - docker-build-step

Setup credentials for Docker Hub private CR:

*Dashboard* -> *Manage Jenkins* -> *Manage Credentials*

Create new credentials with ID: *docker-hub-credentials* (will be used at Jenkinsfile) of **Username and Password** kind

## Project workload

Login to Jenkins and create *New Item* from Dashboard

Choose type of *Pipeline*

- On *General* tab
  Build Triggers -> Poll SCM -> Schedule
  ```shell
  H * * * *
  ```
