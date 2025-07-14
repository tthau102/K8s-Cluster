# Kubernetes Cluster Infrastructure

## Tổng quan

Terraform infrastructure để deploy Kubernetes cluster trên AWS sử dụng official terraform-aws-modules.

## Cấu trúc Project

```
environments/dev/
├── data.tf                 # Data sources (AZs, AMI)
├── locals.tf              # Local values và calculations
├── vpc.tf                 # VPC, subnets, networking
├── security-groups.tf     # Security groups cho K8s components
├── iam.tf                # IAM roles, policies, key pairs
├── ec2.tf                # K8s master & worker instances
├── alb.tf                # Application Load Balancer
├── s3.tf                 # S3 bucket cho ALB logs
├── outputs.tf            # Infrastructure outputs
├── variables.tf          # Variable definitions
├── providers.tf          # Provider configurations
├── versions.tf           # Terraform & provider versions
├── terraform.tfvars      # Actual values (create from example)
└── terraform.tfvars.example # Configuration template
```

## Prerequisites

1. **AWS CLI** configured với appropriate credentials
2. **Terraform** >= 1.0
3. **SSH Key Pair** tại `~/.ssh/id_rsa` và `~/.ssh/id_rsa.pub`

## Quick Start

### 1. Configuration Setup

```bash
# Copy và edit configuration
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

### 2. Backend Setup

Nếu chưa có backend S3:

```bash
cd environments/shared/backend/
terraform init
terraform apply
# Note bucket name từ output
```

Update `versions.tf` với bucket name thực tế.

### 3. Deploy Infrastructure

```bash
cd environments/dev/

# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

## Configuration Options

### Development Environment

```hcl
# terraform.tfvars for dev
project = "k8s-pj"
environment = "dev"
owner = "tth"

# Cost optimization
master_count = 1
worker_count = 2
enable_nat_gateway = false
enable_vpc_endpoints = false
ssl_certificate_arn = null
```

### Production Environment

```hcl
# terraform.tfvars for prod
project = "k8s-pj"
environment = "prod"
owner = "tth"

# High availability
master_count = 3
worker_count = 5
master_instance_type = "m5.large"
worker_instance_type = "m5.xlarge"
enable_nat_gateway = true
enable_vpc_endpoints = true
enable_deletion_protection = true
ssl_certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
```

## Infrastructure Components

### Networking
- **VPC**: Isolated network environment
- **Public Subnets**: ALB, NAT Gateway, Bastion (nếu có)
- **Private Subnets**: K8s nodes
- **NAT Gateway**: Internet access cho private instances
- **VPC Endpoints**: S3, ECR access không qua internet

### Security
- **Master SG**: API server, etcd, kubelet ports
- **Worker SG**: NodePort range, inter-pod communication
- **ALB SG**: HTTP/HTTPS from internet

### Compute
- **Master Nodes**: Control plane components
- **Worker Nodes**: Application workloads
- **IAM Roles**: AWS cloud provider integration

### Load Balancing
- **ALB**: Internet-facing load balancer
- **Target Groups**: K8s ingress NodePort
- **SSL/TLS**: HTTPS termination (optional)

## Post-Deployment

### Access Instances

Instances nằm trong private subnets, sử dụng AWS Systems Manager:

```bash
# Connect to master-1
aws ssm start-session --target i-1234567890abcdef0 --region ap-southeast-5

# Connect to worker-1
aws ssm start-session --target i-0987654321fedcba0 --region ap-southeast-5
```

### Setup Kubernetes

1. **Initialize Cluster** (trên master-1):
```bash
sudo kubeadm init --apiserver-advertise-address=<PRIVATE_IP> \
  --pod-network-cidr=10.244.0.0/16
```

2. **Setup kubectl**:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

3. **Install CNI** (Flannel):
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

4. **Join Workers**:
```bash
# Get join command từ master
kubeadm token create --print-join-command

# Run trên workers
sudo <join-command>
```

### Install Ingress Controller

```bash
# NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# Verify
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## Monitoring & Troubleshooting

### View ALB Logs

ALB access logs được store trong S3 bucket:

```bash
aws s3 ls s3://tth-k8s-pj-dev-alb-logs-<suffix>/alb-access-logs/
```

### Common Issues

1. **Instances not connecting**: Check security groups và VPC endpoints
2. **ALB health check fails**: Verify ingress controller NodePort
3. **Pod networking issues**: Check CNI installation và security groups

## Cost Optimization

### Development
- Single NAT Gateway: ~$45/month
- Disable VPC Endpoints: Save ~$20/month
- Smaller instance types: t3.medium/large

### Production
- Multiple AZs: Higher availability
- VPC Endpoints: Reduce data transfer costs
- Reserved Instances: Up to 75% cost savings

## Security Best Practices

1. **Network Isolation**: Private subnets cho K8s nodes
2. **Encryption**: EBS volumes encrypted
3. **Access Control**: IAM roles với minimum permissions
4. **SSL/TLS**: HTTPS termination tại ALB
5. **Logging**: ALB access logs enabled

## Cleanup

```bash
# Destroy infrastructure
terraform destroy

# Verify S3 bucket empty (nếu có versioning)
aws s3 rm s3://bucket-name --recursive
```

## Support

- **Issues**: Check Terraform plan output và AWS CloudTrail
- **Documentation**: terraform-aws-modules documentation
- **Monitoring**: CloudWatch metrics cho instances và ALB