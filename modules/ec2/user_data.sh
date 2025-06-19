#!/bin/bash
# modules/ec2/user_data.sh
# Kubernetes installation script for Ubuntu 22.04

set -e

# Variables passed from Terraform
KUBERNETES_VERSION="${kubernetes_version}"
CONTAINERD_VERSION="${containerd_version}"
NODE_TYPE="${node_type}"
NODE_INDEX="${node_index}"

# Log setup
LOG_FILE="/var/log/k8s-setup.log"
exec 1> >(tee -a $LOG_FILE)
exec 2>&1

echo "=== Starting Kubernetes setup at $(date) ==="
echo "Node Type: $NODE_TYPE"
echo "Node Index: $NODE_INDEX"
echo "Kubernetes Version: $KUBERNETES_VERSION"

# Update system
apt-get update
apt-get upgrade -y

# Install prerequisites
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    wget

# Disable swap permanently
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure kernel modules
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Configure sysctl params
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Install containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io=$CONTAINERD_VERSION

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# Enable SystemdCgroup
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# Install Kubernetes packages
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
systemctl enable kubelet

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Configure crictl
cat <<EOF | tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
pull-image-on-create: false
EOF

# Set hostname based on node type and index
if [ "$NODE_TYPE" = "master" ]; then
    hostnamectl set-hostname "k8s-master-$NODE_INDEX"
elif [ "$NODE_TYPE" = "worker" ]; then
    hostnamectl set-hostname "k8s-worker-$NODE_INDEX"
fi

# Update /etc/hosts
echo "127.0.0.1 $(hostname)" >> /etc/hosts

# Create script for master initialization (only for first master)
if [ "$NODE_TYPE" = "master" ] && [ "$NODE_INDEX" = "1" ]; then
    cat <<'INIT_SCRIPT' > /root/init-cluster.sh
#!/bin/bash
# Initialize Kubernetes cluster

# Get private IP
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Initialize cluster
kubeadm init \
    --apiserver-advertise-address=$PRIVATE_IP \
    --apiserver-cert-extra-sans=$PRIVATE_IP \
    --pod-network-cidr=10.244.0.0/16 \
    --service-cidr=10.96.0.0/12 \
    --node-name=$(hostname) \
    --v=5

# Setup kubectl for root
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# Setup kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Install Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "=== Cluster initialized successfully ==="
echo "Join command saved to /root/join-command.sh"

# Save join command for other nodes
kubeadm token create --print-join-command > /root/join-command.sh
chmod +x /root/join-command.sh

echo "=== Setup completed at $(date) ==="
INIT_SCRIPT

    chmod +x /root/init-cluster.sh
fi

# Create join script for other masters and workers
if [ "$NODE_TYPE" = "master" ] && [ "$NODE_INDEX" != "1" ] || [ "$NODE_TYPE" = "worker" ]; then
    cat <<'JOIN_SCRIPT' > /root/join-cluster.sh
#!/bin/bash
# Join node to cluster
# This script needs to be run manually after getting the join command from master-1

echo "This script will join the node to the cluster"
echo "Get the join command from master-1 first:"
echo "  ssh master-1 'cat /root/join-command.sh'"
echo ""
echo "Then run the join command with sudo"
JOIN_SCRIPT

    chmod +x /root/join-cluster.sh
fi

# Install useful tools
apt-get install -y \
    htop \
    net-tools \
    jq \
    tree \
    vim

# Configure bash aliases
cat <<EOF >> /home/ubuntu/.bashrc

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdn='kubectl describe node'
EOF

cat <<EOF >> /root/.bashrc

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdn='kubectl describe node'
EOF

# Set correct permissions
chown -R ubuntu:ubuntu /home/ubuntu

echo "=== Kubernetes installation completed at $(date) ==="
echo "Node ready for cluster setup"

# Signal completion
touch /var/log/k8s-setup-complete

# Final system info
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
echo "Kubernetes version: $(kubelet --version)"
echo "Containerd version: $(containerd --version)"
echo "=========================="