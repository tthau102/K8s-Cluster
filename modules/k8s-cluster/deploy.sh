#!/bin/bash
set -e

CLUSTER_NAME=$1
shift
ALL_IPS="$@"

echo "Starting Kubespray deployment for cluster: $CLUSTER_NAME"

# Create working directory
mkdir -p ~/k8s-deployment
cd ~/k8s-deployment

# Clone kubespray if not exists
if [ ! -d 'kubespray' ]; then
  echo 'Cloning Kubespray...'
  git clone https://github.com/kubernetes-sigs/kubespray.git
  cd kubespray
  git checkout v2.24.3
  cd ..
fi

# Create inventory directory structure
mkdir -p kubespray/inventory/$CLUSTER_NAME/group_vars/all
mkdir -p kubespray/inventory/$CLUSTER_NAME/group_vars/k8s_cluster

# Copy uploaded files
cp /tmp/inventory.ini kubespray/inventory/$CLUSTER_NAME/
cp /tmp/all.yml kubespray/inventory/$CLUSTER_NAME/group_vars/all/

# Copy default k8s_cluster configs
cp -r kubespray/inventory/sample/group_vars/k8s_cluster/* kubespray/inventory/$CLUSTER_NAME/group_vars/k8s_cluster/ || true

# Install Docker if not exists
if ! command -v docker &> /dev/null; then
  echo 'Installing Docker...'
  sudo apt update
  sudo apt install -y docker.io
  sudo usermod -aG docker ubuntu
  newgrp docker || true
  echo 'Docker installed and user added to docker group'
fi

# Wait for instances to be ready
echo 'Waiting for instances to be ready...'
sleep 60

# Test connectivity to all nodes
echo 'Testing connectivity to nodes...'
for ip in $ALL_IPS; do
  echo "Testing connection to $ip..."
  ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$ip 'echo Connected to $(hostname)' || echo "Failed to connect to $ip"
done

# Pull kubespray docker image
echo 'Pulling Kubespray Docker image...'
docker pull quay.io/kubespray/kubespray:v2.24.3

# Run kubespray deployment
echo 'Starting Kubespray deployment...'
docker run --rm \
  --mount type=bind,source="$(pwd)/kubespray",target=/kubespray \
  --mount type=bind,source="$HOME/.ssh/id_rsa",target=/root/.ssh/id_rsa,readonly \
  quay.io/kubespray/kubespray:v2.24.3 \
  ansible-playbook -i inventory/$CLUSTER_NAME/inventory.ini \
  --private-key /root/.ssh/id_rsa \
  --become --become-user=root \
  cluster.yml -v

echo 'Kubespray deployment completed!'
