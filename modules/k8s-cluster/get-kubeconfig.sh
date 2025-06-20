#!/bin/bash
set -e

MASTER_IP=$1
KUBE_VERSION=$2

echo "Retrieving kubeconfig from master node: $MASTER_IP"

# Wait a bit for cluster to be fully ready
sleep 30

# Create .kube directory on bastion
mkdir -p ~/.kube

# Copy kubeconfig from master-1
echo "Copying kubeconfig from master node..."
scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no \
  ubuntu@$MASTER_IP:/home/ubuntu/.kube/config \
  ~/.kube/config 2>/dev/null || \
scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no \
  ubuntu@$MASTER_IP:/etc/kubernetes/admin.conf \
  ~/.kube/config

# Fix permissions
chmod 600 ~/.kube/config

# Update server endpoint to use first master private IP
sed -i "s|server:.*|server: https://$MASTER_IP:6443|g" ~/.kube/config

echo 'Kubeconfig configured on bastion host'
echo 'Testing cluster access...'

# Install kubectl if needed
if ! command -v kubectl &> /dev/null; then
  echo 'Installing kubectl...'
  curl -LO "https://dl.k8s.io/release/v$KUBE_VERSION/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
fi

# Test cluster
echo "Testing cluster connectivity..."
kubectl get nodes || echo 'Cluster not ready yet, may need a few more minutes'
kubectl get pods -A | head -10 || echo 'Pods not ready yet'

echo "Kubeconfig setup completed!"
echo "Cluster endpoint: https://$MASTER_IP:6443"
